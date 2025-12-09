import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';
import '../../models/cheque.dart';
import 'cheque_form_view.dart';

class ChequeListView extends StatefulWidget {
  const ChequeListView({super.key});

  @override
  State<ChequeListView> createState() => _ChequeListViewState();
}

class _ChequeListViewState extends State<ChequeListView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();

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
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshStatuses(),
            ),
          ],
        ),
        body: Column(
          children: [
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
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
              ),
            ),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  _ChequeList(
                    cheques: controller.chequesCashed,
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: controller.chequesNear,
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: controller.chequesValid,
                    searchQuery: _searchQuery,
                  ),
                  _ChequeList(
                    cheques: controller.chequesExpired,
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
      final partyName = controller.partyNameFor(c.partyId).toLowerCase();
      return partyName.contains(searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No cheques.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final partyName = controller.partyNameFor(c.partyId);
        return ListTile(
          title: Text('$partyName - ${c.chequeNumber}'),
          subtitle: Text(
              'Amount: ${c.amount.toStringAsFixed(2)} | Due: ${c.dueDate.toLocal().toString().split(' ').first}'),
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
