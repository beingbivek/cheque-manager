import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cheque_controller.dart';
import '../../models/cheque.dart';

class ChequeDetailView extends StatelessWidget {
  final String chequeId;

  const ChequeDetailView({super.key, required this.chequeId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChequeController>();
    final cheque = controller.cheques
        .firstWhere((c) => c.id == chequeId, orElse: () => _dummyCheque());

    final partyName = controller.partyNameFor(cheque.partyId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cheque Details'),
      ),
      body: Padding(
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
                'Issue Date: ${cheque.issueDate.toLocal().toString().split(' ').first}'),
            Text(
                'Due Date: ${cheque.dueDate.toLocal().toString().split(' ').first}'),
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

  Cheque _dummyCheque() {
    final now = DateTime.now();
    return Cheque(
      id: '',
      userId: '',
      partyId: '',
      chequeNumber: '',
      amount: 0,
      issueDate: now,
      dueDate: now,
      status: ChequeStatus.valid,
      createdAt: now,
    );
  }
}
