import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('{{PROJECT}}', style: TextStyle(fontSize: 32)),
              Text('{{ORG}} - {{ENV}}', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
