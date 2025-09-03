
import 'html_service_desktop.dart'
    if (dart.library.html) 'html_service_web.dart' as html_service;

class HtmlService {
  static Future<void> downloadFile(String content, String fileName) async {
    html_service.HtmlService.downloadFile(content, fileName);
  }
}
