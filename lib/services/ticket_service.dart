import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_error.dart';
import '../models/ticket.dart';
import 'firestore_repository.dart';

class TicketService {
  TicketService({FirestoreRepository? repository})
      : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;

  Stream<List<Ticket>> streamTicketsForUser(String userId) {
    return _repository.tickets
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())).toList())
        .handleError((error, stackTrace) {
          throw _wrapError(error);
        });
  }

  Future<void> createTicket({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final doc = _repository.tickets.doc();
      await doc.set({
        'userId': userId,
        'title': title,
        'message': message,
        'status': TicketStatus.open.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppError(
        code: 'FIRESTORE_${e.code.toUpperCase()}',
        message: 'Failed to submit ticket.',
        original: e,
      );
    } catch (e) {
      throw AppError(
        code: 'TICKET_CREATE_UNKNOWN',
        message: 'Unknown error while creating ticket.',
        original: e,
      );
    }
  }

  AppError _wrapError(Object error) {
    if (error is AppError) return error;
    if (error is FirebaseException) {
      return AppError(
        code: 'FIRESTORE_${error.code.toUpperCase()}',
        message: 'Failed to load tickets.',
        original: error,
      );
    }
    return AppError(
      code: 'TICKET_STREAM_UNKNOWN',
      message: 'Unknown error while loading tickets.',
      original: error,
    );
  }
}
