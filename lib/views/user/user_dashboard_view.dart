// lib/views/user/user_dashboard_view.dart
import 'package:flutter/material.dart';

import 'cheque_list_view.dart';
import 'party_list_view.dart';
import 'user_settings_view.dart';

class UserDashboardView extends StatefulWidget {
  const UserDashboardView({super.key});

  @override
  State<UserDashboardView> createState() => _UserDashboardViewState();
}

class _UserDashboardViewState extends State<UserDashboardView> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    ChequeListView(),
    PartyListView(),
    UserSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() => _currentIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Cheques',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups),
            label: 'Parties',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
