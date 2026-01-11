import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/app_error.dart';
import '../../models/ticket.dart';
import '../../services/ticket_service.dart';

class UserTicketsView extends StatefulWidget {
  const UserTicketsView({super.key});

  @override
  State<UserTicketsView> createState() => _UserTicketsViewState();
}

class _UserTicketsViewState extends State<UserTicketsView> {
  final TicketService _service = TicketService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AppError? _error;
  bool _submitting = false;
  TicketStatus? _statusFilter;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.createTicket(
        userId: userId,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      _titleController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted.')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view tickets.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    _ErrorBanner(error: _error!),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a message'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submit(user.uid),
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit ticket'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Ticket>>(
              stream: _service.streamTicketsForUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = snapshot.data!;
                return _TicketList(
                  tickets: tickets,
                  statusFilter: _statusFilter,
                  onFilterChanged: (value) =>
                      setState(() => _statusFilter = value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.tickets,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  final List<Ticket> tickets;
  final TicketStatus? statusFilter;
  final ValueChanged<TicketStatus?> onFilterChanged;

  void _exportCsv(BuildContext context, List<Ticket> entries) {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tickets to export.')),
      );
      return;
    }
    final buffer = StringBuffer()..writeln('title,status,createdAt');
    for (final ticket in entries) {
      final createdAt = ticket.createdAt == null
          ? ''
          : ticket.createdAt!.toLocal().toString().split(' ').first;
      buffer.writeln('${ticket.title},${ticket.status.name},$createdAt');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tickets copied as CSV.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = tickets
        .where((ticket) => statusFilter == null || ticket.status == statusFilter)
        .toList();
    if (tickets.isEmpty) {
      return const Center(child: Text('No tickets yet.'));
    }
    final openCount = tickets.where((t) => t.status == TicketStatus.open).length;
    final progressCount =
        tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolvedCount =
        tickets.where((t) => t.status == TicketStatus.resolved).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TicketStatus?>(
                      value: statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status filter',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All statuses')),
                        DropdownMenuItem(
                          value: TicketStatus.open,
                          child: Text('Open'),
                        ),
                        DropdownMenuItem(
                          value: TicketStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: TicketStatus.resolved,
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: onFilterChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _exportCsv(context, filtered),
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: 'Open', count: openCount),
                  _SummaryChip(label: 'In Progress', count: progressCount),
                  _SummaryChip(label: 'Resolved', count: resolvedCount),
                  _SummaryChip(label: 'Filtered', count: filtered.length),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No tickets match filters.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    return ListTile(
                      title: Text(ticket.title),
                      subtitle: Text(ticket.message),
                      trailing: Text(ticket.status.name),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $count'));
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 12),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeError(error);
    return Center(
      child: Text(
        '${normalized.message}\nCode: ${normalized.code}',
        textAlign: TextAlign.center,
      ),
    );
  }

  AppError _normalizeError(Object? error) {
    if (error is AppError) return error;
    return AppError(
      code: 'TICKETS_LOAD_ERROR',
      message: 'Unable to load tickets.',
      original: error,
    );
  }
}
