import 'export_helper_base.dart';

class ExportHelperImpl implements ExportHelper {
  @override
  Future<void> save({
    required String filename,
    required String mimeType,
    required String data,
  }) {
    throw UnsupportedError('Export is not supported on this platform.');
  }
}
