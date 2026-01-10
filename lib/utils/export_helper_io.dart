import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_helper_base.dart';

class ExportHelperImpl implements ExportHelper {
  @override
  Future<void> save({
    required String filename,
    required String mimeType,
    required String data,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(data, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: filename,
    );
  }
}
