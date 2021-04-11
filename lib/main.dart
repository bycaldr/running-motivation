import 'package:flutter/material.dart';

import 'widgets/pages/main.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // app root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running Motivation 🏃',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Main(title: 'Running Motivation 🏃'),
    );
  }
}
