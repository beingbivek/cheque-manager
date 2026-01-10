import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/cheque.dart';
import '../models/party.dart';
import '../models/app_error.dart';
import '../services/cheque_service.dart';
import '../services/party_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class ChequeController extends ChangeNotifier {
  final ChequeService _chequeService = ChequeService();
  final PartyService _partyService = PartyService();
  final UserService _userService = UserService();

  int _nearThresholdDays = 3;
  User? _user;
  List<Cheque> _cheques = [];
  List<Party> _parties = [];
  AppError? _lastError;
  bool _isLoading = false;

  void setUser(User? user) {
    _user = user;
    if (user != null) {
      _nearThresholdDays = user.notificationLeadDays;
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
  int get nearThresholdDays => _nearThresholdDays;

  List<Cheque> get cheques => _cheques;
  List<Party> get parties => _parties;

  // Filtered lists
  List<Cheque> get chequesCashed =>
      _sectionedCheques()[ChequeStatus.cashed]!;

  List<Cheque> get chequesNear => _sectionedCheques()[ChequeStatus.near]!;

  List<Cheque> get chequesValid => _sectionedCheques()[ChequeStatus.valid]!;

  List<Cheque> get chequesExpired => _sectionedCheques()[ChequeStatus.expired]!;

  Map<ChequeStatus, List<Cheque>> get chequeSections => _sectionedCheques();

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

  String displayPartyName(Cheque cheque) {
    if (cheque.partyName.trim().isNotEmpty) {
      return cheque.partyName;
    }

    if (cheque.partyId.isNotEmpty) {
      return partyNameFor(cheque.partyId);
    }

    return 'Unknown';
  }

  void setNearThresholdDays(int days) {
    _nearThresholdDays = days;
    notifyListeners();
  }

  Future<void> loadData() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      _lastError = null;
      _nearThresholdDays = _user?.notificationLeadDays ?? _nearThresholdDays;
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

  Future<void> updateNotificationLeadDays(int days) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      _lastError = null;
      await _userService.updateNotificationLeadDays(
        userId: _user!.uid,
        leadDays: days,
      );
      _nearThresholdDays = days;

      for (final cheque in _cheques) {
        if (cheque.status == ChequeStatus.cashed) continue;
        await _chequeService.updateNotificationSent(
          chequeId: cheque.id,
          notificationSent: false,
        );
      }

      _cheques = _cheques
          .map((cheque) => cheque.status == ChequeStatus.cashed
              ? cheque
              : cheque.copyWith(notificationSent: false))
          .toList();

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
    required DateTime date,
  }) async {
    if (_user == null) {
      _lastError = AppError(code: 'NO_USER', message: 'User not logged in.');
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _lastError = null;

      final userProfile = await _userService.fetchUser(_user!.uid);

      // enforce subscription limits
      final isPro = userProfile.isPro;
      final maxParties = isPro ? 50 : 5;
      final maxCheques = isPro ? 50 : 5;

      final existingParty = await _partyService.findByName(
        userId: _user!.uid,
        name: partyName,
      );

      if (existingParty == null && userProfile.partyCount >= maxParties) {
        throw AppError(
          code: 'LIMIT_PARTY',
          message:
              'You reached the maximum parties (${maxParties}). Upgrade to Pro to add more.',
        );
      }

      if (userProfile.chequeCount >= maxCheques) {
        throw AppError(
          code: 'LIMIT_CHEQUE',
          message:
              'You reached the maximum cheques (${maxCheques}). Upgrade to Pro to add more.',
        );
      }

      // create or get party
      final party = existingParty ??
          await _partyService.createParty(
            userId: _user!.uid,
            name: partyName,
          );

      final status = _calculateStatus(date, cashed: false);
      final now = DateTime.now();

      final cheque = Cheque(
        id: '',
        userId: _user!.uid,
        partyId: party.id,
        partyName: partyName,
        chequeNumber: chequeNumber,
        amount: amount,
        date: date,
        status: status,
        notificationSent: false,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _chequeService.addCheque(cheque);
      _cheques.add(saved);
      if (!_parties.any((p) => p.id == party.id)) {
        _parties.add(party);
      }
      notifyListeners();
    } on AppError catch (e) {
      _lastError = e;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addParty({
    required String name,
    String? phone,
    String? notes,
  }) async {
    if (_user == null) {
      _lastError = AppError(code: 'NO_USER', message: 'User not logged in.');
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _lastError = null;
      final existing = await _partyService.findByName(
        userId: _user!.uid,
        name: name,
      );
      if (existing != null) {
        throw AppError(
          code: 'PARTY_EXISTS',
          message: 'Party already exists.',
        );
      }
      final created = await _partyService.createParty(
        userId: _user!.uid,
        name: name,
      );
      final updated = created.copyWith(
        phone: phone,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      if (phone != null || notes != null) {
        await _partyService.updateParty(
          partyId: updated.id,
          updates: {
            'phone': phone,
            'notes': notes,
            'updatedAt': DateTime.now(),
          },
        );
      }
      _parties = [..._parties, updated];
      notifyListeners();
    } on AppError catch (e) {
      _lastError = e;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateParty({
    required String partyId,
    required String name,
    String? phone,
    String? notes,
    required PartyStatus status,
  }) async {
    final index = _parties.indexWhere((p) => p.id == partyId);
    if (index == -1) {
      _lastError = AppError(
        code: 'PARTY_NOT_FOUND',
        message: 'Party not found.',
      );
      notifyListeners();
      return;
    }

    _setLoading(true);
    final current = _parties[index];
    final updated = Party(
      id: current.id,
      userId: current.userId,
      name: name,
      phone: phone,
      notes: notes,
      status: status,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );

    final optimistic = List<Party>.from(_parties);
    optimistic[index] = updated;
    _parties = optimistic;
    notifyListeners();

    try {
      await _partyService.updateParty(
        partyId: partyId,
        updates: {
          'name': name,
          'phone': phone,
          'notes': notes,
          'status': status.name,
          'updatedAt': DateTime.now(),
        },
      );
    } on AppError catch (e) {
      final reverted = List<Party>.from(_parties);
      reverted[index] = current;
      _parties = reverted;
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
          updated.add(c);
          continue;
        }

        final newStatus = _calculateStatus(c.date, cashed: false);

        // If it just became "near" and no notification yet -> notify
        if (newStatus == ChequeStatus.near && !c.notificationSent) {
          final partyName = displayPartyName(c);
          await NotificationService.instance.showChequeReminder(
            cheque: c,
            partyName: partyName,
          );

          await _chequeService.markNotificationSent(c.id);

          final now = DateTime.now();
          updated.add(
            c.copyWith(
              status: newStatus,
              notificationSent: true,
              updatedAt: now,
            ),
          );
        } else if (newStatus != c.status) {
          final now = DateTime.now();
          await _chequeService.updateChequeStatus(
            chequeId: c.id,
            status: newStatus,
            updatedAt: now,
          );
          updated.add(c.copyWith(status: newStatus, updatedAt: now));
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
    await updateChequeStatus(
      chequeId: chequeId,
      status: ChequeStatus.cashed,
    );
  }

  Future<void> updateChequeStatus({
    required String chequeId,
    required ChequeStatus status,
  }) async {
    final index = _cheques.indexWhere((c) => c.id == chequeId);
    if (index == -1) {
      _lastError = AppError(
        code: 'CHEQUE_NOT_FOUND',
        message: 'Cheque not found.',
      );
      notifyListeners();
      return;
    }

    final current = _cheques[index];
    if (current.status == status) {
      _lastError = AppError(
        code: 'STATUS_ALREADY_SET',
        message: 'Cheque is already ${status.name}.',
      );
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final optimistic = current.copyWith(status: status, updatedAt: now);
    final updated = List<Cheque>.from(_cheques);
    updated[index] = optimistic;
    _cheques = updated;
    _lastError = null;
    notifyListeners();

    try {
      await _chequeService.updateChequeStatus(
        chequeId: chequeId,
        status: status,
        updatedAt: now,
      );
      _lastError = null;
      notifyListeners();
    } on AppError catch (e) {
      final reverted = List<Cheque>.from(_cheques);
      reverted[index] = current;
      _cheques = reverted;
      _lastError = e;
      notifyListeners();
    }
  }

  Future<void> updateCheque({
    required String chequeId,
    required String partyName,
    required String chequeNumber,
    required double amount,
    required DateTime date,
    required ChequeStatus status,
  }) async {
    final index = _cheques.indexWhere((c) => c.id == chequeId);
    if (index == -1) {
      _lastError = AppError(
        code: 'CHEQUE_NOT_FOUND',
        message: 'Cheque not found.',
      );
      notifyListeners();
      return;
    }

    final current = _cheques[index];
    final now = DateTime.now();
    final recalculatedStatus =
        status == ChequeStatus.cashed ? status : _calculateStatus(date, cashed: false);
    final updatedCheque = current.copyWith(
      partyName: partyName,
      chequeNumber: chequeNumber,
      amount: amount,
      date: date,
      status: recalculatedStatus,
      notificationSent: false,
      updatedAt: now,
    );

    final optimistic = List<Cheque>.from(_cheques);
    optimistic[index] = updatedCheque;
    _cheques = optimistic;
    _lastError = null;
    notifyListeners();

    try {
      await _chequeService.updateCheque(
        chequeId: chequeId,
        updates: {
          'partyName': partyName,
          'chequeNumber': chequeNumber,
          'amount': amount,
          'date': date,
          'status': recalculatedStatus.name,
          'notificationSent': false,
          'updatedAt': now,
        },
      );
      await refreshStatuses();
    } on AppError catch (e) {
      final reverted = List<Cheque>.from(_cheques);
      reverted[index] = current;
      _cheques = reverted;
      _lastError = e;
      notifyListeners();
    }
  }

  // Helper: recalc status based on dates
  ChequeStatus _calculateStatus(DateTime chequeDate, {required bool cashed}) {
    if (cashed) return ChequeStatus.cashed;

    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final due = DateTime(chequeDate.year, chequeDate.month, chequeDate.day);

    if (due.isBefore(d)) {
      return ChequeStatus.expired;
    }

    if (due.difference(d).inDays <= _nearThresholdDays) {
      return ChequeStatus.near;
    }

    return ChequeStatus.valid;
  }

  Map<ChequeStatus, List<Cheque>> _sectionedCheques() {
    final sections = {
      ChequeStatus.cashed: <Cheque>[],
      ChequeStatus.near: <Cheque>[],
      ChequeStatus.valid: <Cheque>[],
      ChequeStatus.expired: <Cheque>[],
    };

    for (final cheque in _cheques) {
      sections[_deriveStatus(cheque)]!.add(cheque);
    }

    return sections;
  }

  ChequeStatus _deriveStatus(Cheque cheque) {
    if (cheque.status == ChequeStatus.cashed) {
      return ChequeStatus.cashed;
    }

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final chequeDate =
        DateTime(cheque.date.year, cheque.date.month, cheque.date.day);

    if (chequeDate.isBefore(day)) {
      return ChequeStatus.expired;
    }

    if (cheque.isNear(
      thresholdDays: _nearThresholdDays,
      referenceDate: day,
    )) {
      return ChequeStatus.near;
    }

    return ChequeStatus.valid;
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
