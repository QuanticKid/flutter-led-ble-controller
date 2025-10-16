// lib/main.dart

import 'package:flutter/material.dart';
import 'features/Devices/View/main_view.dart';
import 'package:flutter/gestures.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('PointerAddedEvent') &&
        details.exceptionAsString().contains('PointerRemovedEvent')) {
      // Просто пропускаем
      return;
    }
    FlutterError.presentError(details); // остальные ошибки выводим как обычно
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LED Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MainView(), // <<< Самое важное: стартуем с MainView
    );
  }
}
