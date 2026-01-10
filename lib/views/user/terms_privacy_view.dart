import 'package:flutter/material.dart';

import '../../models/app_error.dart';
import '../../models/legal_doc.dart';
import '../../services/legal_doc_service.dart';

class TermsPrivacyView extends StatelessWidget {
  const TermsPrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: StreamBuilder<List<LegalDoc>>(
        stream: LegalDocService().streamPublishedDocs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(child: Text('No published documents yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doc.docType.toUpperCase()} · ${doc.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${doc.version} · Published ${_formatDate(doc.publishedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(doc.content),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${normalized.message}\nCode: ${normalized.code}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  AppError _normalizeError(Object? error) {
    if (error is AppError) return error;
    return AppError(
      code: 'TERMS_LOAD_ERROR',
      message: 'Unable to load legal documents.',
      original: error,
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'unknown';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
