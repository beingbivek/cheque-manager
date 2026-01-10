import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';

class AdminLegalDocDialog extends StatefulWidget {
  const AdminLegalDocDialog({super.key, required this.doc});

  final LegalDoc doc;

  @override
  State<AdminLegalDocDialog> createState() => _AdminLegalDocDialogState();
}

class _AdminLegalDocDialogState extends State<AdminLegalDocDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _versionController;

  AppError? _error;
  bool _submitting = false;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _contentController = TextEditingController(text: widget.doc.content);
    _versionController = TextEditingController(text: widget.doc.version);
    _isPublished = widget.doc.publishedAt != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final publishedAt = _isPublished
          ? widget.doc.publishedAt ?? DateTime.now()
          : null;
      await context.read<AdminController>().updateLegalDoc(
            docId: widget.doc.id,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            version: _versionController.text.trim(),
            publishedAt: publishedAt,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Legal document updated.')),
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
    return AlertDialog(
      title: Text('Edit ${widget.doc.docType.toUpperCase()}'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                _ErrorBanner(error: _error!),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter content'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _versionController,
                decoration: const InputDecoration(labelText: 'Version'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter version'
                    : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published'),
                subtitle: Text(
                  _isPublished
                      ? 'Published on ${_formatDate(widget.doc.publishedAt ?? DateTime.now())}'
                      : 'Not published',
                ),
                value: _isPublished,
                onChanged: _submitting
                    ? null
                    : (value) {
                        setState(() => _isPublished = value);
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
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

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
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
    );
  }
}
