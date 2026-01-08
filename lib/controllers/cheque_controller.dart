import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/cheque.dart';
import '../models/party.dart';
import '../models/app_error.dart';
import '../services/cheque_service.dart';
import '../services/party_service.dart';
import '../services/notification_service.dart';


class ChequeController extends ChangeNotifier {
  final ChequeService _chequeService = ChequeService();
  final PartyService _partyService = PartyService();

  AppUser? _user;
  List<Cheque> _cheques = [];
  List<Party> _parties = [];
  AppError? _lastError;
  bool _isLoading = false;

  void setUser(AppUser? user) {
    _user = user;
    if (user != null) {
      loadData();
    } else {
      _cheques = [];
      _parties = [];
      _lastError = null;
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;
  AppError? get lastError => _lastError;

  List<Cheque> get cheques => _cheques;
  List<Party> get parties => _parties;

  // Filtered lists
  List<Cheque> get chequesCashed =>
      _cheques.where((c) => c.status == ChequeStatus.cashed).toList();

  List<Cheque> get chequesNear =>
      _cheques.where((c) => c.status == ChequeStatus.near).toList();

  List<Cheque> get chequesValid =>
      _cheques.where((c) => c.status == ChequeStatus.valid).toList();

  List<Cheque> get chequesExpired =>
      _cheques.where((c) => c.status == ChequeStatus.expired).toList();

  String partyNameFor(String partyId) => _parties
      .firstWhere(
        (p) => p.id == partyId,
        orElse: () => Party(
          id: partyId,
          userId: _user?.uid ?? '',
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      )
      .name;

  Future<void> loadData() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      _lastError = null;
      _parties = await _partyService.getPartiesForUser(_user!.uid);
      _cheques = await _chequeService.getChequesForUser(_user!.uid);

      // auto adjust statuses based on current date
      await refreshStatuses();
    } on AppError catch (e) {
      _lastError = e;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> addCheque({
    required String partyName,
    required String chequeNumber,
    required double amount,
    required DateTime issueDate,
    required DateTime dueDate,
  }) async {
    if (_user == null) {
      _lastError = AppError(code: 'NO_USER', message: 'User not logged in.');
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _lastError = null;

      // enforce subscription limits
      final isPro = _user!.isPro;
      final maxParties = isPro ? 50 : 5;
      final maxCheques = isPro ? 50 : 5;

      final partyCount = await _partyService.countPartiesForUser(_user!.uid);
      if (partyCount >= maxParties) {
        throw AppError(
          code: 'LIMIT_PARTY',
          message:
              'You reached the maximum parties (${maxParties}). Upgrade to Pro to add more.',
        );
      }

      final chequeCount = await _chequeService.countChequesForUser(_user!.uid);
      if (chequeCount >= maxCheques) {
        throw AppError(
          code: 'LIMIT_CHEQUE',
          message:
              'You reached the maximum cheques (${maxCheques}). Upgrade to Pro to add more.',
        );
      }

      // create or get party
      final party = await _partyService.createOrGetByName(
        userId: _user!.uid,
        name: partyName,
      );

      final status = _calculateStatus(dueDate, cashed: false);

      final cheque = Cheque(
        id: '',
        userId: _user!.uid,
        partyId: party.id,
        chequeNumber: chequeNumber,
        amount: amount,
        issueDate: issueDate,
        dueDate: dueDate,
        status: status,
        notificationSent: false,
        createdAt: DateTime.now(),
      );

      final saved = await _chequeService.addCheque(cheque);
      _cheques.add(saved);
      if (!_parties.any((p) => p.id == party.id)) {
        _parties.add(party);
      }
      await _scheduleChequeReminders(saved);
      notifyListeners();
    } on AppError catch (e) {
      _lastError = e;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshStatuses() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      _lastError = null;

      final List<Cheque> updated = [];
      for (final c in _cheques) {
        if (c.status == ChequeStatus.cashed) {
          await _cancelChequeReminders(c);
          updated.add(c);
          continue;
        }

        final newStatus = _calculateStatus(c.dueDate, cashed: false);
        if (newStatus == ChequeStatus.expired) {
          await _cancelChequeReminders(c);
        } else {
          await _scheduleChequeReminders(c);
        }

        // If it just became "near" and no notification yet -> notify
        if (newStatus == ChequeStatus.near && !c.notificationSent) {
          final partyName = partyNameFor(c.partyId);
          await NotificationService.instance.showChequeReminder(
            cheque: c,
            partyName: partyName,
          );

          await _chequeService.markNotificationSent(c.id);

          updated.add(
            c.copyWith(
              status: newStatus,
              notificationSent: true,
            ),
          );
        } else if (newStatus != c.status) {
          await _chequeService.updateChequeStatus(
            chequeId: c.id,
            status: newStatus,
          );
          updated.add(c.copyWith(status: newStatus));
        } else {
          updated.add(c);
        }
      }

      _cheques = updated;
      notifyListeners();
    } on AppError catch (e) {
      _lastError = e;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }


  Future<void> markAsCashed(String chequeId) async {
    try {
      await _chequeService.updateChequeStatus(
        chequeId: chequeId,
        status: ChequeStatus.cashed,
      );
      final cheque = _cheques.firstWhere((c) => c.id == chequeId);
      await _cancelChequeReminders(cheque);
      _cheques = _cheques
          .map(
            (c) =>
                c.id == chequeId ? c.copyWith(status: ChequeStatus.cashed) : c,
          )
          .toList();
      notifyListeners();
    } on AppError catch (e) {
      _lastError = e;
      notifyListeners();
    }
  }

  // Helper: recalc status based on dates
  ChequeStatus _calculateStatus(DateTime dueDate, {required bool cashed}) {
    if (cashed) return ChequeStatus.cashed;

    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(d)) {
      return ChequeStatus.expired;
    }

    final diff = due.difference(d).inDays;
    if (diff <= 3) {
      return ChequeStatus.near;
    }

    return ChequeStatus.valid;
  }

  Future<void> _scheduleChequeReminders(Cheque cheque) async {
    if (_user == null) return;
    if (cheque.status == ChequeStatus.cashed ||
        cheque.status == ChequeStatus.expired) {
      return;
    }
    final reminderDays =
        _user!.reminderDays.isEmpty ? [1, 3, 7] : _user!.reminderDays;
    if (reminderDays.isEmpty) return;
    final partyName = partyNameFor(cheque.partyId);
    await NotificationService.instance.scheduleChequeReminders(
      cheque: cheque,
      partyName: partyName,
      reminderDays: reminderDays,
    );
  }

  Future<void> _cancelChequeReminders(Cheque cheque) async {
    if (_user == null) return;
    final reminderDays =
        _user!.reminderDays.isEmpty ? [1, 3, 7] : _user!.reminderDays;
    await NotificationService.instance.cancelChequeReminders(
      chequeId: cheque.id,
      reminderDays: reminderDays,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
