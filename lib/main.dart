import 'package:douget/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DouGet',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfff3f8fb),
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
