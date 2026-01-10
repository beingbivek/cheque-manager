import 'package:flutter/material.dart';

import '../../models/legal_doc.dart';
import '../../services/legal_doc_service.dart';

class TermsPrivacyView extends StatelessWidget {
  const TermsPrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LegalDocService();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms & Privacy'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terms'),
              Tab(text: 'Privacy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalDocPanel(
              title: 'Terms of Service',
              docStream: service.streamLatestPublishedDoc('terms'),
            ),
            _LegalDocPanel(
              title: 'Privacy Policy',
              docStream: service.streamLatestPublishedDoc('privacy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocPanel extends StatelessWidget {
  const _LegalDocPanel({
    required this.title,
    required this.docStream,
  });

  final String title;
  final Stream<LegalDoc?> docStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LegalDoc?>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load $title.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snapshot.data;
        if (doc == null) {
          return Center(
            child: Text(
              'No published $title yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              doc.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Version ${doc.version}'
              '${doc.publishedAt == null ? '' : ' · Published ${_formatDate(doc.publishedAt!)}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SelectableText(
              doc.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
