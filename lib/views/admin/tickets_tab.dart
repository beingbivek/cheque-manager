import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/ticket.dart';
import '../../utils/export_helper.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final TextEditingController _searchController = TextEditingController();
  TicketStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setStatusFilter(TicketStatus? status) {
    setState(() => _statusFilter = status);
  }

  Future<void> _exportTickets(List<Ticket> tickets, ExportFormat format) async {
    if (tickets.isEmpty) {
      _showSnackBar('No tickets to export.');
      return;
    }
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'tickets_report_$now.${format.extension}';
    final payload = format == ExportFormat.csv
        ? TicketExport.toCsv(tickets)
        : jsonEncode(TicketExport.toJson(tickets));
    final mimeType = format == ExportFormat.csv
        ? 'text/csv'
        : 'application/json';

    try {
      await getExportHelper().save(
        filename: filename,
        mimeType: mimeType,
        data: payload,
      );
      _showSnackBar('Exported $filename');
    } catch (error) {
      _showSnackBar('Failed to export tickets.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminController>();

    return Column(
      children: [
        _FiltersCard(
          searchController: _searchController,
          statusFilter: _statusFilter,
          onSearchChanged: (_) => setState(() {}),
          onStatusSelected: _setStatusFilter,
        ),
        Expanded(
          child: StreamBuilder<List<Ticket>>(
            stream: controller.streamTickets(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorBanner(error: snapshot.error);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final tickets = _applyFilters(snapshot.data!);
              if (tickets.isEmpty) {
                return const _EmptyState();
              }
              return Column(
                children: [
                  _SummaryRow(
                    total: tickets.length,
                    openCount: tickets
                        .where((ticket) => ticket.status == TicketStatus.open)
                        .length,
                    onExport: (format) =>
                        _exportTickets(tickets, format),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final createdAt = ticket.createdAt == null
                            ? 'Unknown'
                            : _formatDateTime(ticket.createdAt!);
                        return _TicketTile(
                          ticket: ticket,
                          createdAt: createdAt,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Ticket> _applyFilters(List<Ticket> tickets) {
    final query = _searchController.text.trim().toLowerCase();
    return tickets.where((ticket) {
      if (_statusFilter != null && ticket.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return ticket.subject.toLowerCase().contains(query) ||
          ticket.description.toLowerCase().contains(query) ||
          ticket.userId.toLowerCase().contains(query) ||
          ticket.requesterEmail.toLowerCase().contains(query);
    }).toList();
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusSelected,
  });

  final TextEditingController searchController;
  final TicketStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TicketStatus?> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by subject, user, or email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                DropdownButton<TicketStatus?>(
                  value: statusFilter,
                  hint: const Text('Status: All'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Status: All'),
                    ),
                    ...TicketStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text('Status: ${_statusLabel(status)}'),
                      ),
                    ),
                  ],
                  onChanged: onStatusSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.openCount,
    required this.onExport,
  });

  final int total;
  final int openCount;
  final ValueChanged<ExportFormat> onExport;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tickets: $total · Open: $openCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<ExportFormat>(
                tooltip: 'Export tickets',
                onSelected: onExport,
                icon: Icon(
                  Icons.download,
                  color: colorScheme.primary,
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ExportFormat.csv,
                    child: Text('Export CSV'),
                  ),
                  PopupMenuItem(
                    value: ExportFormat.json,
                    child: Text('Export JSON'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({
    required this.ticket,
    required this.createdAt,
  });

  final Ticket ticket;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AdminController>();
    final subtitle = [
      if (ticket.requesterEmail.isNotEmpty) ticket.requesterEmail,
      if (ticket.userId.isNotEmpty) 'User: ${ticket.userId}',
      'Priority: ${ticket.priority}',
      'Category: ${ticket.category}',
    ].join(' · ');

    return ListTile(
      title: Text(ticket.subject),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(createdAt),
          DropdownButton<TicketStatus>(
            value: ticket.status,
            items: TicketStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value == null || value == ticket.status) return;
              try {
                await controller.updateTicketStatus(
                  ticketId: ticket.id,
                  status: value,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Ticket ${ticket.id} set to ${value.name}.'),
                  ),
                );
              } on AppError catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${e.message} (Code: ${e.code})'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No tickets found for the selected filters.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        error == null ? 'Something went wrong.' : 'Error: $error',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  return value.toLocal().toString().split('.').first;
}

String _statusLabel(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return 'Open';
    case TicketStatus.pending:
      return 'Pending';
    case TicketStatus.resolved:
      return 'Resolved';
    case TicketStatus.closed:
      return 'Closed';
  }
}

class TicketExport {
  const TicketExport._();

  static Map<String, dynamic> toJson(List<Ticket> tickets) {
    return {
      'count': tickets.length,
      'tickets': tickets.map(_mapTicket).toList(),
    };
  }

  static String toCsv(List<Ticket> tickets) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,userId,requesterEmail,subject,description,category,priority,status,createdAt,updatedAt',
    );
    for (final ticket in tickets) {
      buffer.writeln(
        [
          _escape(ticket.id),
          _escape(ticket.userId),
          _escape(ticket.requesterEmail),
          _escape(ticket.subject),
          _escape(ticket.description),
          _escape(ticket.category),
          _escape(ticket.priority),
          _escape(ticket.status.name),
          _escape(ticket.createdAt?.toIso8601String() ?? ''),
          _escape(ticket.updatedAt?.toIso8601String() ?? ''),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  static Map<String, dynamic> _mapTicket(Ticket ticket) {
    return {
      'id': ticket.id,
      'userId': ticket.userId,
      'requesterEmail': ticket.requesterEmail,
      'subject': ticket.subject,
      'description': ticket.description,
      'category': ticket.category,
      'priority': ticket.priority,
      'status': ticket.status.name,
      'createdAt': ticket.createdAt?.toIso8601String(),
      'updatedAt': ticket.updatedAt?.toIso8601String(),
    };
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}

enum ExportFormat {
  csv('csv'),
  json('json');

  const ExportFormat(this.extension);

  final String extension;
}
