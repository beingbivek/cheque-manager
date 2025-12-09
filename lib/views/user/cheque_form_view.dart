import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';

class ChequeFormView extends StatefulWidget {
  const ChequeFormView({super.key});

  @override
  State<ChequeFormView> createState() => _ChequeFormViewState();
}

class _ChequeFormViewState extends State<ChequeFormView> {
  final _formKey = GlobalKey<FormState>();

  final _partyCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DateTime? _issueDate;
  DateTime? _dueDate;

  bool _submitting = false;
  AppError? _localError;

  @override
  void dispose() {
    _partyCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final controller = context.read<ChequeController>();

    if (!_formKey.currentState!.validate()) return;

    if (_issueDate == null || _dueDate == null) {
      setState(() {
        _localError = AppError(
          code: 'FORM_DATE_MISSING',
          message: 'Please select both issue date and due date.',
        );
      });
      return;
    }

    if (_dueDate!.isBefore(_issueDate!)) {
      setState(() {
        _localError = AppError(
          code: 'FORM_DATE_INVALID',
          message: 'Due date cannot be before issue date.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    try {
      final amount = double.tryParse(_amountCtrl.text.trim());
      if (amount == null || amount <= 0) {
        setState(() {
          _localError = AppError(
            code: 'FORM_AMOUNT_INVALID',
            message: 'Enter a valid amount.',
          );
          _submitting = false;
        });
        return;
      }

      await controller.addCheque(
        partyName: _partyCtrl.text.trim(),
        chequeNumber: _chequeNumberCtrl.text.trim(),
        amount: amount,
        issueDate: _issueDate!,
        dueDate: _dueDate!,
      );

      if (controller.lastError == null) {
        if (mounted) Navigator.of(context).pop(); // go back to list
      } else {
        setState(() {
          _localError = controller.lastError;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();

    final error = _localError ?? controller.lastError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cheque'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Card(
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
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _partyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Party Name',
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter party name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chequeNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cheque Number',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter cheque number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Issue Date'),
                          subtitle: Text(
                            _issueDate == null
                                ? 'Select date'
                                : _issueDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first,
                          ),
                          onTap: _pickIssueDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Due Date'),
                          subtitle: Text(
                            _dueDate == null
                                ? 'Select date'
                                : _dueDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first,
                          ),
                          onTap: _pickDueDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text('Save Cheque'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
