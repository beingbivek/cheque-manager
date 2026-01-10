import 'dart:html' as html;

import 'export_helper_base.dart';

class ExportHelperImpl implements ExportHelper {
  @override
  Future<void> save({
    required String filename,
    required String mimeType,
    required String data,
  }) async {
    final blob = html.Blob([data], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
