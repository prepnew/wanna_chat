import 'package:flutter/material.dart';

import 'package:wanna_chat_app/screens/login_screen.dart';

void main() {
  runApp(const WannaChatApp());
}

class WannaChatApp extends StatelessWidget {
  const WannaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wanna Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
