import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lab2_patient_app/screens/action_page.dart';
import 'package:lab2_patient_app/screens/patients_screen.dart';

import 'configuration/firebase_options.dart';
import 'configuration/http_override.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab2 App',
      debugShowCheckedModeBanner: false,
      home:
          FirebaseAuth.instance.currentUser == null
              ? const LoginPage()
              : MainNavigationScreen(
                email: FirebaseAuth.instance.currentUser?.email,
              ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final String? email;

  const MainNavigationScreen({super.key, required this.email});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([PatientsScreen(email: widget.email), ActionButtons()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) => setState(() => _currentIndex = newIndex),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacienți'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Acțiuni',
          ),
        ],
      ),
    );
  }
}
