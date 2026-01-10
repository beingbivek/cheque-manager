import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/legal_doc.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    final controller = context.read<AdminController>();

    try {
      final publishedAt = _isPublished
          ? widget.doc.publishedAt ?? DateTime.now()
          : null;
      await controller.updateLegalDoc(
        docId: widget.doc.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        version: _versionController.text.trim(),
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
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Version is required'
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
