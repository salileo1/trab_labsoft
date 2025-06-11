import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:trab_labsoft/components/login/cadastro_container.dart';
import 'package:trab_labsoft/components/utils/toast_snackbar.dart';
import 'package:trab_labsoft/models/users/usuario_form_data.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';

class cadastroPage extends StatefulWidget {
  final void Function(UsuarioFormData formData)? onSubmit;
  const cadastroPage({super.key, this.onSubmit});

  @override
  State<cadastroPage> createState() => _cadastroPageState();
}

class _cadastroPageState extends State<cadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formData =
      UsuarioFormData(); // Mover para cá para ser acessível no cadastrar

  String? _generoSelecionado;
  DateTime? _dataNascimento;

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 1000;
    // final UsuarioFormData _formData = UsuarioFormData(); // Removido daqui

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 5, 146, 24)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButtonFormField<TipoUsuario>(
                          decoration:
                              InputDecoration(labelText: 'Tipo de Usuário'),
                          value: _formData.tipoUsuario,
                          items: TipoUsuario.values.map((TipoUsuario tipo) {
                            return DropdownMenuItem<TipoUsuario>(
                              value: tipo,
                              child: Text(tipoUsuarioToString(
                                  tipo)), // Assumindo que tipoUsuarioToString existe
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _formData.tipoUsuario =
                                  value ?? TipoUsuario.hospital;
                            });
                          },
                          // onSaved não é necessário aqui se _formData é variável de estado
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione o tipo de usuário.';
                            }
                            return null;
                          },
                        ),
                        _buildTextField("Nome", _nomeController),
                        _buildTextField("Email", _emailController),
                        _buildTextField("Senha", _passwordController,
                            obscureText: true),
                        _buildTextField("Telefone", _telefoneController),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_nomeController.text.toLowerCase() ==
                                  'bloqueio') {
                                showToast(
                                    context,
                                    'Não foi possível cadastrar',
                                    'Não é permitido criar um usuario com esse nome',
                                    ToastificationType.error);
                              } else {
                                cadastrar();
                              }
                            },
                            child: Text('Cadastrar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                )),
                            style: ElevatedButton.styleFrom(
                              elevation: 10.0,
                              backgroundColor: Color.fromARGB(255, 5, 146, 24),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 20.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLargeScreen) CadastroCustomContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            label,
            style: TextStyle(
              color: Color.fromARGB(255, 5, 146, 24),
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
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
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String label, String? selectedValue, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            label,
            style: TextStyle(
              color: Color.fromARGB(255, 5, 146, 24),
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _generoSelecionado = newValue;
            });
          },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
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
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            label,
            style: TextStyle(
              color: Color.fromARGB(255, 5, 146, 24),
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _dataNascimento == null
                ? ''
                : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 15,
            ),
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(20),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dataNascimento) {
      setState(() {
        _dataNascimento = picked;
      });
    }
  }

  Future<void> cadastrar() async {
    // Adicionar validação básica dos campos se necessário
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nomeController.text.isEmpty ||
        _formData.tipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os campos obrigatórios."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // 1. Criar usuário no Firebase Auth
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final uid = user.uid;

        // 2. Atualizar nome no Auth (opcional, mas bom ter)
        await user.updateDisplayName(_nomeController.text.trim());

        // 3. Preparar dados para Firestore
        final userData = {
          'uid': uid,
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'genero': _generoSelecionado,
          'dataNascimento': _dataNascimento != null
              ? Timestamp.fromDate(_dataNascimento!)
              : null,
          'tipoUsuario': tipoUsuarioToString(
              _formData.tipoUsuario), // Usar a função helper
          'fornecedores': [],
          'createdAt': Timestamp.now(), // Adicionar timestamp de criação
        };

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('usuarioId', uid);
        prefs.setString('usuarioNome', _nomeController.text.trim());
        prefs.setString(
          'tipoUsuario',
          tipoUsuarioToString(_formData.tipoUsuario),
        );

        // 4. Salvar dados no Firestore
        await _firestore.collection('users').doc(uid).set(userData);

        // 5. Navegar para a próxima página APÓS sucesso
        // ignore: use_build_context_synchronously
        if (!mounted) return; // Verificar se o widget ainda está montado
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const checkPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      if (!mounted) return;
      String message = "Ocorreu um erro no cadastro.";
      if (e.code == 'weak-password') {
        message = "Crie uma senha mais forte";
      } else if (e.code == 'email-already-in-use') {
        message = "Email já cadastrado";
      } else if (e.code == 'invalid-email') {
        message = "Email inválido";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      // Tratar erros do Firestore ou outros erros gerais
      // ignore: use_build_context_synchronously
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar dados: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// Função helper para converter enum para String (coloque onde fizer sentido no seu projeto)
String tipoUsuarioToString(TipoUsuario tipo) {
  switch (tipo) {
    case TipoUsuario.hospital:
      return 'Hospital';
    case TipoUsuario.fornecedor:
      return 'Fornecedor';
    // Adicione outros casos se houver
    default:
      return 'Desconhecido';
  }
}
