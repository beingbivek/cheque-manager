import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../common/app_error_banner.dart';

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
  bool _published = false;

  AppError? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _contentController = TextEditingController(text: widget.doc.content);
    _versionController =
        TextEditingController(text: widget.doc.version.toString());
    _published = widget.doc.publishedAt != null;
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
      await context.read<AdminController>().updateLegalDoc(
            docId: widget.doc.id,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            version: int.parse(_versionController.text.trim()),
            publishedAt: _published ? DateTime.now() : null,
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
    if (widget.doc.id.isEmpty) {
      final error = AppError(
        code: 'LEGAL_DOC_ID_MISSING',
        message: 'Missing legal document ID.',
      );
      return AlertDialog(
        title: const Text('Legal document unavailable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We could not load this legal document. Please try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppErrorBanner(error: error),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false),
            child: const Text('Go Home'),
          ),
        ],
      );
    }
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
                AppErrorBanner(
                  error: _error!,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
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
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid version';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published'),
                value: _published,
                onChanged: (value) {
                  if (_submitting) return;
                  setState(() => _published = value);
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
