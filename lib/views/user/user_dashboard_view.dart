// lib/views/user/user_dashboard_view.dart
import 'package:flutter/material.dart';
import 'cheque_list_view.dart';

class UserDashboardView extends StatelessWidget {
  const UserDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChequeListView();
  }
}
