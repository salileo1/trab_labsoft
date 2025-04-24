import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trab_labsoft/components/login/login_container.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';


import 'cadastro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;


  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        
      ),
      body: Row(
        children: [
          if (isLargeScreen) LoginCustomContainer(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ALUGUEL DE INSTRUMENTAIS CIRÚGICOS')
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          "Email",
                          style: TextStyle(
                            color: Color.fromARGB(255, 5, 146, 24),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextFormField(
                        key: const ValueKey('email'),
                        controller: _emailController,
                        decoration: InputDecoration(
                          contentPadding:const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Montserrat',
                        ),
                        validator: (localEmail) {
                          final email = localEmail ?? '';
                          if (!email.contains('@')) {
                            return 'E-mail informado não é válido.';
                          }
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          "Senha",
                          style: TextStyle(
                            color: Color.fromARGB(255, 5, 146, 24),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextFormField(
                        key: const ValueKey('password'),
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Montserrat',
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (localPassword) {
                          final password = localPassword ?? '';
                          if (password.length < 6) {
                            return 'Senha deve ter no mínimo 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            login();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 10.0,
                            backgroundColor: Color.fromARGB(255, 5, 146, 24),
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  20.0, // Ajuste a altura conforme necessário
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Novo usuário?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 5, 146, 24),
                                  )),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => cadastroPage()),
                                  );
                                },
                                child: const Text(
                                  'Crie sua conta!',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 105, 4),
                                  ),
                                ),
                              )
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  login() async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => checkPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usuário não encontrado"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (e.code == "wrong-password") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha incorreta"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
