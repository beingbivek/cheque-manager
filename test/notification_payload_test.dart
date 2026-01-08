import 'package:flutter_test/flutter_test.dart';

import 'package:cheque_manager/services/notification_service.dart';
import 'package:cheque_manager/routes/app_routes.dart';

void main() {
  test('buildPayload includes chequeId and route', () {
    const chequeId = 'cheque-123';

    final payload = NotificationService.buildPayload(chequeId);
    final parsed = NotificationService.parsePayload(payload);

    expect(parsed[NotificationService.payloadRouteKey], AppRoutes.chequeDetails);
    expect(parsed[NotificationService.payloadChequeIdKey], chequeId);
  });
}
