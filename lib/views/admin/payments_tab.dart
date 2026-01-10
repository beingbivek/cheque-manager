import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../models/app_error.dart';
import '../../models/payment_record.dart';
import '../../utils/export_helper.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _planController = TextEditingController();

  PaymentsFilter _filter = const PaymentsFilter();
  PaymentReport? _report;
  bool _loading = false;
  String? _errorMessage;
  bool _hasGenerated = false;

  @override
  void dispose() {
    _providerController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filter.dateRange,
    );
    if (range == null) return;
    setState(() {
      _filter = _filter.copyWith(dateRange: range);
    });
  }

  Future<void> _runReport() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final controller = context.read<AdminController>();
      final range = _filter.dateRange;
      final end = range == null
          ? null
          : DateTime(
              range.end.year,
              range.end.month,
              range.end.day,
              23,
              59,
              59,
            );
      final payments = await controller.fetchFilteredPayments(
        startDate: range?.start,
        endDate: end,
        provider: _filter.provider,
        plan: _filter.plan,
      );
      setState(() {
        _report = PaymentReport.fromPayments(payments);
        _hasGenerated = true;
      });
    } catch (error) {
      final message = error is AppError
          ? error.message
          : 'Failed to load filtered payments.';
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _filter = const PaymentsFilter();
      _report = null;
      _hasGenerated = false;
    });
    _providerController.clear();
    _planController.clear();
  }

  Future<void> _exportReport(ExportFormat format) async {
    if (!_hasGenerated || _report == null) {
      _showSnackBar('Generate a report before exporting.');
      return;
    }
    if (_report!.payments.isEmpty) {
      _showSnackBar('No payments to export.');
      return;
    }

    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'payments_report_$now.${format.extension}';
    final payload = format == ExportFormat.csv
        ? _report!.toCsv()
        : jsonEncode(_report!.toJson());
    final mimeType = format == ExportFormat.csv
        ? 'text/csv'
        : 'application/json';

    try {
      await getExportHelper().save(
        filename: filename,
        mimeType: mimeType,
        data: payload,
      );
      _showSnackBar('Exported $filename');
    } catch (error) {
      _showSnackBar('Failed to export report.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Column(
      children: [
        _FiltersCard(
          filter: _filter,
          providerController: _providerController,
          planController: _planController,
          onDateRangePressed: _pickDateRange,
          onProviderChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(provider: value);
            });
          },
          onPlanChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(plan: value);
            });
          },
          onGenerate: _loading ? null : _runReport,
          onClear: _loading ? null : _resetFilters,
          onExport: _loading ? null : _exportReport,
        ),
        if (_loading)
          const LinearProgressIndicator(minHeight: 2),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ErrorBanner(message: _errorMessage!),
          ),
        if (_hasGenerated)
          _SummaryCard(report: report),
        Expanded(
          child: _PaymentsList(
            report: report,
            hasGenerated: _hasGenerated,
          ),
        ),
      ],
    );
  }
}

class PaymentsFilter {
  const PaymentsFilter({
    this.dateRange,
    this.provider = '',
    this.plan = '',
  });

  final DateTimeRange? dateRange;
  final String provider;
  final String plan;

  PaymentsFilter copyWith({
    DateTimeRange? dateRange,
    String? provider,
    String? plan,
  }) {
    return PaymentsFilter(
      dateRange: dateRange ?? this.dateRange,
      provider: provider ?? this.provider,
      plan: plan ?? this.plan,
    );
  }

  String get dateRangeLabel {
    if (dateRange == null) return 'Select date range';
    final start = _formatDate(dateRange!.start);
    final end = _formatDate(dateRange!.end);
    return '$start → $end';
  }
}

class PaymentReport {
  PaymentReport({required this.payments});

  final List<PaymentRecord> payments;

  int get count => payments.length;

  double get totalAmount =>
      payments.fold(0, (total, item) => total + item.amountValue);

  int get freeCount =>
      payments.where((payment) => !_isProPlan(payment.planGranted)).length;

  int get proCount =>
      payments.where((payment) => _isProPlan(payment.planGranted)).length;

  double get monthlyRecurringRevenue {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return payments
        .where((payment) =>
            payment.createdAt != null && payment.createdAt!.isAfter(cutoff))
        .fold(0, (total, item) => total + item.amountValue);
  }

  static PaymentReport fromPayments(List<PaymentRecord> payments) {
    return PaymentReport(payments: payments);
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalAmount': totalAmount,
      'monthlyRecurringRevenue': monthlyRecurringRevenue,
      'freeCount': freeCount,
      'proCount': proCount,
      'payments': payments.map(_mapPayment).toList(),
    };
  }

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('id,userId,provider,planGranted,amount,createdAt');
    for (final payment in payments) {
      buffer.writeln(
        [
          _escape(payment.id),
          _escape(payment.userId),
          _escape(payment.provider),
          _escape(payment.planGranted),
          payment.amountValue.toStringAsFixed(2),
          _escape(payment.createdAt?.toIso8601String() ?? ''),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  static Map<String, dynamic> _mapPayment(PaymentRecord payment) {
    return {
      'id': payment.id,
      'userId': payment.userId,
      'provider': payment.provider,
      'planGranted': payment.planGranted,
      'amount': payment.amountValue,
      'createdAt': payment.createdAt?.toIso8601String(),
    };
  }

  static bool _isProPlan(String plan) {
    final normalized = plan.toLowerCase();
    return normalized.contains('pro') ||
        normalized.contains('premium') ||
        normalized.contains('paid');
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.filter,
    required this.providerController,
    required this.planController,
    required this.onDateRangePressed,
    required this.onProviderChanged,
    required this.onPlanChanged,
    required this.onGenerate,
    required this.onClear,
    required this.onExport,
  });

  final PaymentsFilter filter;
  final TextEditingController providerController;
  final TextEditingController planController;
  final VoidCallback onDateRangePressed;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onPlanChanged;
  final VoidCallback? onGenerate;
  final VoidCallback? onClear;
  final ValueChanged<ExportFormat>? onExport;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: onDateRangePressed,
                  icon: const Icon(Icons.date_range),
                  label: Text(filter.dateRangeLabel),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: providerController,
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onProviderChanged,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: planController,
                    decoration: const InputDecoration(
                      labelText: 'Plan',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onPlanChanged,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Generate Report'),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear Filters'),
                ),
                PopupMenuButton<ExportFormat>(
                  tooltip: 'Export report',
                  onSelected: onExport,
                  enabled: onExport != null,
                  icon: Icon(
                    Icons.download,
                    color: onExport == null
                        ? colorScheme.onSurface.withOpacity(0.38)
                        : colorScheme.primary,
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ExportFormat.csv,
                      child: Text('Export CSV'),
                    ),
                    PopupMenuItem(
                      value: ExportFormat.json,
                      child: Text('Export JSON'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final PaymentReport? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: _SummaryTile(
                  label: 'Payments',
                  value: report!.count.toString(),
                ),
              ),
              SizedBox(
                width: 180,
                child: _SummaryTile(
                  label: 'Total Amount',
                  value: report!.totalAmount.toStringAsFixed(2),
                ),
              ),
              SizedBox(
                width: 180,
                child: _SummaryTile(
                  label: 'MRR (30d)',
                  value: report!.monthlyRecurringRevenue.toStringAsFixed(2),
                ),
              ),
              SizedBox(
                width: 180,
                child: _SummaryTile(
                  label: 'Free vs Pro',
                  value: '${report!.freeCount} / ${report!.proCount}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: textTheme.titleLarge),
      ],
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList({
    required this.report,
    required this.hasGenerated,
  });

  final PaymentReport? report;
  final bool hasGenerated;

  @override
  Widget build(BuildContext context) {
    if (!hasGenerated) {
      return const Center(
        child: Text('Run a report to see payment results.'),
      );
    }

    if (report == null || report!.payments.isEmpty) {
      return const Center(
        child: Text('No payments matched the selected filters.'),
      );
    }

    final payments = report!.payments;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final payment = payments[index];
        final subtitle =
            '${payment.provider} · ${payment.planGranted} · ${payment.userId}';
        final date = payment.createdAt == null
            ? 'Unknown date'
            : _formatDateTime(payment.createdAt!);

        return ListTile(
          title: Text(
            '₹${payment.amountValue.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(subtitle),
          trailing: Text(date),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime value) {
  return value.toLocal().toString().split('.').first;
}

enum ExportFormat {
  csv('csv'),
  json('json');

  const ExportFormat(this.extension);

  final String extension;
}
