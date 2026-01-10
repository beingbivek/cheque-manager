import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';
import '../../models/party.dart';

class PartyListView extends StatefulWidget {
  const PartyListView({super.key});

  @override
  State<PartyListView> createState() => _PartyListViewState();
}

class _PartyListViewState extends State<PartyListView> {
  String _searchQuery = '';
  PartyStatus? _statusFilter;
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
    final parties = controller.parties.where((party) {
      if (_statusFilter != null && party.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final haystack = [
        party.name,
        party.phone ?? '',
        party.notes ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const _PartyDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search parties',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PartyStatus?>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status filter',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(
                            value: PartyStatus.active,
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: PartyStatus.archived,
                            child: Text('Archived'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Count: ${parties.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: parties.isEmpty
                ? const Center(child: Text('No parties yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: parties.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final party = parties[index];
                      return ListTile(
                        title: Text(party.name),
                        subtitle: Text(
                          [
                            if (party.phone != null && party.phone!.isNotEmpty)
                              'Phone: ${party.phone}',
                            if (party.notes != null && party.notes!.isNotEmpty)
                              'Notes: ${party.notes}',
                            'Status: ${party.status.name}',
                          ].join('\n'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (_) => _PartyDialog(party: party),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartyDialog extends StatefulWidget {
  const _PartyDialog({this.party});

  final Party? party;

  @override
  State<_PartyDialog> createState() => _PartyDialogState();
}

class _PartyDialogState extends State<_PartyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  PartyStatus _status = PartyStatus.active;
  AppError? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.party?.name ?? '');
    _phoneController = TextEditingController(text: widget.party?.phone ?? '');
    _notesController = TextEditingController(text: widget.party?.notes ?? '');
    _status = widget.party?.status ?? PartyStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = context.read<ChequeController>();
    try {
      if (widget.party == null) {
        await controller.addParty(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
        );
      } else {
        await controller.updateParty(
          partyId: widget.party!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          status: _status,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.party == null
              ? 'Party created.'
              : 'Party updated.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.party == null ? 'New Party' : 'Edit Party'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                _ErrorBanner(error: _error!),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PartyStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: PartyStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _status = value);
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
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
