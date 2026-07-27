import 'package:flutter/material.dart';
import 'screens/shelf_screen.dart';

void main() {
  runApp(const ChapterOneApp());
}

class ChapterOneApp extends StatelessWidget {
  const ChapterOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChapterOne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
      ),
      home: const ShelfScreen(),
    );
  }
}
