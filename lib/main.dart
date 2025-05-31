import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:trab_labsoft/firebase_options.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';
import 'package:trab_labsoft/pages/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


 runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InstrumentaisList()),
      ],
      child:  DevicePreview(
        enabled: true,
        builder: (context) => MyApp(), 
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aluga Instrumentais',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasData) {
              return const checkPage();
            } else {
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}
