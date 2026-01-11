import 'dart:async';

import 'upgrade_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _exportCheques() {
    final controller = context.read<ChequeController>();
    final filtered = controller.cheques.where((c) {
      if (_searchQuery.isEmpty) return true;
      final partyName = controller.displayPartyName(c).toLowerCase();
      return partyName.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cheques to export.')),
      );
      return;
    }

    final buffer = StringBuffer()
      ..writeln('partyName,chequeNumber,amount,date,status');
    for (final cheque in filtered) {
      final partyName = controller.displayPartyName(cheque);
      final date = cheque.date.toLocal().toString().split(' ').first;
      buffer.writeln(
        '$partyName,${cheque.chequeNumber},${cheque.amount.toStringAsFixed(2)},'
        '$date,${cheque.status.name}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cheques copied as CSV.')),
    );
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
              icon: const Icon(Icons.support_agent),
              onPressed: () =>
                  Navigator.pushNamed(context, '/tickets'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () =>
                  Navigator.pushNamed(context, '/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.groups),
              onPressed: () =>
                  Navigator.pushNamed(context, '/parties'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshStatuses(),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportCheques,
            ),
          ],
        ),
        body: Column(
          children: [
            const UpgradeBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        label: 'Settings',
                        icon: Icons.settings,
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      _QuickAction(
                        label: 'Notifications',
                        icon: Icons.notifications,
                        onTap: () =>
                            Navigator.pushNamed(context, '/notifications'),
                      ),
                      _QuickAction(
                        label: 'Tickets',
                        icon: Icons.support_agent,
                        onTap: () => Navigator.pushNamed(context, '/tickets'),
                      ),
                      _QuickAction(
                        label: 'Parties',
                        icon: Icons.groups,
                        onTap: () => Navigator.pushNamed(context, '/parties'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    label: 'Cashed',
                    count: sections[ChequeStatus.cashed]?.length ?? 0,
                  ),
                  _SummaryChip(
                    label: 'Near',
                    count: sections[ChequeStatus.near]?.length ?? 0,
                  ),
                  _SummaryChip(
                    label: 'Valid',
                    count: sections[ChequeStatus.valid]?.length ?? 0,
                  ),
                  _SummaryChip(
                    label: 'Expired',
                    count: sections[ChequeStatus.expired]?.length ?? 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
          onTap: () {
            Navigator.pushNamed(
              context,
              '/cheque-details',
              arguments: c.id,
            );
          },
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;

  const _SummaryChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
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
