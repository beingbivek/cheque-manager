import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../common/app_error_banner.dart';

class EditLegalDocDialog extends StatefulWidget {
  const EditLegalDocDialog({super.key, required this.doc});

  final LegalDoc doc;

  @override
  State<EditLegalDocDialog> createState() => _EditLegalDocDialogState();
}

class _EditLegalDocDialogState extends State<EditLegalDocDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _versionController;
  bool _isSaving = false;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _contentController = TextEditingController(text: widget.doc.content);
    _versionController = TextEditingController(text: widget.doc.version.toString());
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    final controller = context.read<AdminController>();

    try {
      final version = int.tryParse(_versionController.text.trim());
      if (version == null) {
        throw AppError(
          code: 'LEGAL_DOC_VERSION_INVALID',
          message: 'Version must be a number.',
        );
      }
      final publishedAt = _isPublished
          ? widget.doc.publishedAt ?? DateTime.now()
          : null;
      await controller.updateLegalDoc(
        docId: widget.doc.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        version: version,
        publishedAt: publishedAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error is AppError ? error.message : 'Failed to save.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() => _isSaving = false);
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
      title: Text('Edit ${widget.doc.docType}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                minLines: 6,
                maxLines: 12,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Content is required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _versionController,
                decoration: const InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Version is required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Version must be a number';
                  }
                  return null;
                },
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
                onChanged: _isSaving
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
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
