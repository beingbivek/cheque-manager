import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/app_error.dart';
import '../../models/cheque.dart';
import '../../routes/app_routes.dart';
import '../common/error_screen_view.dart';

class ChequeDetailView extends StatefulWidget {
  final String chequeId;

  const ChequeDetailView({super.key, required this.chequeId});

  @override
  State<ChequeDetailView> createState() => _ChequeDetailViewState();
}

class _ChequeDetailViewState extends State<ChequeDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _partyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DateTime? _chequeDate;
  ChequeStatus? _selectedStatus;

  bool _isEditing = false;
  bool _submitting = false;
  AppError? _localError;

  @override
  void dispose() {
    _partyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickChequeDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      setState(() => _chequeDate = picked);
    }
  }

  void _startEditing(Cheque cheque, ChequeController controller) {
    setState(() {
      _isEditing = true;
      _localError = null;
      _partyCtrl.text = controller.displayPartyName(cheque);
      _amountCtrl.text = cheque.amount.toStringAsFixed(2);
      _chequeDate = cheque.date;
      _selectedStatus = _displayStatus(cheque, controller.nearThresholdDays);
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
      _localError = null;
    });
  }

  Future<void> _submit(Cheque cheque) async {
    final controller = context.read<ChequeController>();
    if (!_formKey.currentState!.validate()) return;

    if (_chequeDate == null) {
      setState(() {
        _localError = AppError(
          code: 'FORM_DATE_MISSING',
          message: 'Please select the cheque date.',
        );
      });
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _localError = AppError(
          code: 'FORM_AMOUNT_INVALID',
          message: 'Enter a valid amount.',
        );
      });
      return;
    }

    final status = _selectedStatus ?? cheque.status;

    setState(() {
      _submitting = true;
      _localError = null;
    });

    try {
      await controller.updateChequeDetails(
        chequeId: cheque.id,
        partyName: _partyCtrl.text.trim(),
        amount: amount,
        date: _chequeDate!,
        status: status,
      );

      if (controller.lastError == null) {
        if (mounted) {
          _stopEditing();
        }
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

  ChequeStatus _displayStatus(Cheque cheque, int thresholdDays) {
    if (cheque.status == ChequeStatus.cashed) {
      return ChequeStatus.cashed;
    }

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final chequeDate =
        DateTime(cheque.date.year, cheque.date.month, cheque.date.day);

    if (chequeDate.isBefore(day)) {
      return ChequeStatus.expired;
    }

    if (cheque.isNear(thresholdDays: thresholdDays, referenceDate: day)) {
      return ChequeStatus.near;
    }

    return ChequeStatus.valid;
  }

  String _formatDate(DateTime date) => date.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();
    Cheque? cheque;
    for (final item in controller.cheques) {
      if (item.id == widget.chequeId) {
        cheque = item;
        break;
      }
    }

    if (widget.chequeId.isEmpty || cheque == null) {
      return ErrorScreenView(
        title: 'Cheque unavailable',
        message: 'This cheque could not be found. It may have been deleted.',
        actionLabel: 'Go to Dashboard',
        onAction: () => Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.userDashboard,
          (route) => false,
        ),
      );
    }

    final partyName = controller.displayPartyName(cheque);
    final statusLabel =
        _displayStatus(cheque, controller.nearThresholdDays).name;
    final error = _localError ?? controller.lastError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cheque Details'),
        actions: [
          IconButton(
            tooltip: _isEditing ? 'Cancel' : 'Edit',
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () =>
                _isEditing ? _stopEditing() : _startEditing(cheque!, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              partyName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Cheque No: ${cheque.chequeNumber}'),
            Text('Amount: Rs ${cheque.amount.toStringAsFixed(2)}'),
            Text('Date: ${_formatDate(cheque.date)}'),
            Text('Status: $statusLabel'),
            const SizedBox(height: 24),
            if (_isEditing)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _partyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Party Name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter party name'
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
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter amount'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cheque Date'),
                      subtitle: Text(
                        _chequeDate == null
                            ? 'Select date'
                            : _formatDate(_chequeDate!),
                      ),
                      onTap: _pickChequeDate,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ChequeStatus>(
                      value: _selectedStatus,
                      items: ChequeStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _submit(cheque!),
                        child: _submitting
                            ? const CircularProgressIndicator()
                            : const Text('Save Changes'),
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
