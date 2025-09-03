// lib\services\html_service_web.dart
//import 'dart:html' as html;
import 'dart:convert';

class HtmlService {
  static void downloadFile(String content, String fileName) {
    final bytes = const Utf8Encoder().convert(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}