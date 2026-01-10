abstract class ExportHelper {
  Future<void> save({
    required String filename,
    required String mimeType,
    required String data,
  });
}
