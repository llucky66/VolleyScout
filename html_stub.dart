// Questo file fornisce stub per le funzionalità di dart:html quando l'app non è in esecuzione sul web
import 'dart:async';

class Window {
  Map<String, String> localStorage = {};
  Map<String, String> sessionStorage = {};
}

final window = Window();

class Blob {
  Blob(List<dynamic> content);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  
  void setAttribute(String name, String value) {}
  void click() {}
}

class FileUploadInputElement {
  String accept = '';
  List<File>? files;
  
  void click() {}
  
  Stream<Event> get onChange => Stream.empty();
}

class Event {}

class FileReader {
  dynamic result;
  
  Stream<Event> get onLoad => Stream.empty();
  
  void readAsText(File file) {}
}

class File {
  String name = '';
  int size = 0;
}

class Document {
  Body? body;
  
  List<Element> getElementsByTagName(String tagName) => [];
}

class Body {
  List<Element> children = [];
  
  void append(Element element) {}
}

class Element {
  void remove() {}
}
