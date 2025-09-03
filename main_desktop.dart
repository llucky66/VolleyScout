import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configura finestra per tablet simulation
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),  // Simula tablet landscape
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const MyApp()); 
}
