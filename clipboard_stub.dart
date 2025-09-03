// lib/utils/clipboard_stub.dart

class Clipboard {
  static Future<ClipboardData?> getData(String format) async {
    return const ClipboardData(text: '');
  }
}

class ClipboardData {
  final String? text;
  const ClipboardData({this.text});
}
