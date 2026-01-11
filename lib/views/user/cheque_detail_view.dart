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
      final error = AppError(
        code: 'CHEQUE_NOT_FOUND',
        message: 'Missing or invalid cheque ID.',
      );
      return ErrorScreenView(
        title: 'Cheque unavailable',
        message: 'This cheque could not be found. It may have been deleted.',
        error: error,
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
            icon: const Icon(Icons.edit),
            onPressed: cheque.id.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChequeEditView(cheque: cheque),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: cheque.id.isEmpty
            ? const Center(
                child: Text('Cheque not found. It may have been deleted.'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partyName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Cheque No: ${cheque.chequeNumber}'),
                  Text('Amount: Rs ${cheque.amount.toStringAsFixed(2)}'),
                  Text(
                    'Date: ${cheque.date.toLocal().toString().split(' ').first}',
                  ),
                  Text('Status: ${cheque.status.name}'),
                  const SizedBox(height: 16),
                  if (cheque.status != ChequeStatus.cashed)
                    ElevatedButton(
                      onPressed: () {
                        controller.markAsCashed(cheque.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Mark as Cashed'),
                    ),
                ],
              ),
      ),
    );
  }
}

class ChequeEditView extends StatefulWidget {
  const ChequeEditView({super.key, required this.cheque});

  final Cheque cheque;

  @override
  State<ChequeEditView> createState() => _ChequeEditViewState();
}

class _ChequeEditViewState extends State<ChequeEditView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partyController;
  late final TextEditingController _chequeNumberController;
  late final TextEditingController _amountController;
  DateTime? _chequeDate;
  ChequeStatus _status = ChequeStatus.valid;
  AppError? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _partyController = TextEditingController(text: widget.cheque.partyName);
    _chequeNumberController =
        TextEditingController(text: widget.cheque.chequeNumber);
    _amountController =
        TextEditingController(text: widget.cheque.amount.toStringAsFixed(2));
    _chequeDate = widget.cheque.date;
    _status = widget.cheque.status;
  }

  @override
  void dispose() {
    _partyController.dispose();
    _chequeNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_chequeDate == null) {
      setState(() {
        _error = AppError(
          code: 'FORM_DATE_MISSING',
          message: 'Please select the cheque date.',
        );
      });
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _error = AppError(
          code: 'FORM_AMOUNT_INVALID',
          message: 'Enter a valid amount.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<ChequeController>().updateCheque(
            chequeId: widget.cheque.id,
            partyName: _partyController.text.trim(),
            chequeNumber: _chequeNumberController.text.trim(),
            amount: amount,
            date: _chequeDate!,
            status: _status,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cheque updated.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Cheque')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
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
                          '${_error!.message}\nCode: ${_error!.code}',
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
                    controller: _partyController,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter party name'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chequeNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Cheque Number'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter cheque number'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter amount'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ChequeStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ChequeStatus.values
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
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cheque Date'),
                    subtitle: Text(
                      _chequeDate == null
                          ? 'Select date'
                          : _chequeDate!.toLocal().toString().split(' ').first,
                    ),
                    onTap: _saving ? null : _pickDate,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
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

class ChequeEditView extends StatefulWidget {
  const ChequeEditView({super.key, required this.cheque});

  final Cheque cheque;

  @override
  State<ChequeEditView> createState() => _ChequeEditViewState();
}

class _ChequeEditViewState extends State<ChequeEditView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partyController;
  late final TextEditingController _chequeNumberController;
  late final TextEditingController _amountController;
  DateTime? _chequeDate;
  ChequeStatus _status = ChequeStatus.valid;
  AppError? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _partyController = TextEditingController(text: widget.cheque.partyName);
    _chequeNumberController =
        TextEditingController(text: widget.cheque.chequeNumber);
    _amountController =
        TextEditingController(text: widget.cheque.amount.toStringAsFixed(2));
    _chequeDate = widget.cheque.date;
    _status = widget.cheque.status;
  }

  @override
  void dispose() {
    _partyController.dispose();
    _chequeNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_chequeDate == null) {
      setState(() {
        _error = AppError(
          code: 'FORM_DATE_MISSING',
          message: 'Please select the cheque date.',
        );
      });
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _error = AppError(
          code: 'FORM_AMOUNT_INVALID',
          message: 'Enter a valid amount.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<ChequeController>().updateCheque(
            chequeId: widget.cheque.id,
            partyName: _partyController.text.trim(),
            chequeNumber: _chequeNumberController.text.trim(),
            amount: amount,
            date: _chequeDate!,
            status: _status,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cheque updated.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Cheque')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
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
                          '${_error!.message}\nCode: ${_error!.code}',
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
                    controller: _partyController,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter party name'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chequeNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Cheque Number'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter cheque number'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter amount'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ChequeStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ChequeStatus.values
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
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cheque Date'),
                    subtitle: Text(
                      _chequeDate == null
                          ? 'Select date'
                          : _chequeDate!.toLocal().toString().split(' ').first,
                    ),
                    onTap: _saving ? null : _pickDate,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
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
