import 'dart:async';

import 'upgrade_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';
import '../../models/cheque.dart';
import '../../routes/app_routes.dart';
import 'cheque_form_view.dart';
import 'user_settings_view.dart';

class ChequeListView extends StatefulWidget {
  const ChequeListView({super.key});

  @override
  State<ChequeListView> createState() => _ChequeListViewState();
}

class _ChequeListViewState extends State<ChequeListView> {
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();
    final sections = controller.chequeSections;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cheques'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cashed'),
              Tab(text: 'Very Near'),
              Tab(text: 'Valid'),
              Tab(text: 'Expired'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () =>
                  Navigator.pushNamed(context, '/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshStatuses(),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserSettingsView(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Terms & Privacy',
              icon: const Icon(Icons.description_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.termsPrivacy);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const UpgradeBanner(),
            if (controller.lastError != null)
              _ErrorBanner(error: controller.lastError!),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by party name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  _ChequeList(
                    cheques: sections[ChequeStatus.cashed] ?? [],
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: sections[ChequeStatus.near] ?? [],
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: sections[ChequeStatus.valid] ?? [],
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: sections[ChequeStatus.expired] ?? [],
                    searchQuery: _searchQuery,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChequeFormView()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ChequeList extends StatelessWidget {
  final List<Cheque> cheques;
  final String searchQuery;

  const _ChequeList({
    required this.cheques,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();

    final filtered = cheques.where((c) {
      if (searchQuery.isEmpty) return true;
      final partyName = controller.displayPartyName(c).toLowerCase();
      return partyName.contains(searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No cheques.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final partyName = controller.displayPartyName(c);
        return ListTile(
          title: Text('$partyName - ${c.chequeNumber}'),
          subtitle: Text(
              'Amount: ${c.amount.toStringAsFixed(2)} | Date: ${c.date.toLocal().toString().split(' ').first}'),
          trailing: c.status == ChequeStatus.cashed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: () =>
                controller.markAsCashed(c.id),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppError error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${error.message}\nCode: ${error.code}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
