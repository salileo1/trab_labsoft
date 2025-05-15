import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String? _generoSelecionado;
  DateTime? _dataNascimento;

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 1000;
    final UsuarioFormData _formData = UsuarioFormData();

    return Scaffold(
       backgroundColor: Color(0xFFF2E8C7),
      appBar: AppBar(
        backgroundColor: Color(0xFFF2E8C7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF212E38)),
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
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/sense-pel.appspot.com/o/image-removebg-preview.png?alt=media&token=9a7a4329-f7b2-4d95-bc97-1d9fd7959f51',
                            height: 150,
                            width: 150,
                          ),
                        ],
                      ),
                      DropdownButtonFormField<TipoUsuario>(
                        decoration: InputDecoration(labelText: 'Tipo de Usuário'),
                        value: _formData.tipoUsuario,
                        items: TipoUsuario.values.map((TipoUsuario tipo) {
                          return DropdownMenuItem<TipoUsuario>(
                            value: tipo,
                            child: Text(tipoUsuarioToString(tipo)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _formData.tipoUsuario = value ?? TipoUsuario.hospital;
                          });
                        },
                        onSaved: (value) => _formData.tipoUsuario = value ?? TipoUsuario.hospital,
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione o tipo de usuário.';
                          }
                          return null;
                        },
                      ),
                        _buildTextField("Nome completo", _nomeController),
                        _buildTextField("Email", _emailController),
                        _buildTextField("Senha", _passwordController, obscureText: true),
                        _buildTextField("Telefone", _telefoneController),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField("Gênero", _generoSelecionado, ['Masculino', 'Feminino', 'Outro']),
                            ),
                            SizedBox(width: 15),  // Espaço entre os dois campos
                            Expanded(
                              child: _buildDateField("Data de Nascimento", context),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_nomeController.text.toLowerCase() == 'bloqueio') {
                              showToast(context, 'Não foi possível cadastrar', 'Não é permitido criar um usuario com esse nome', ToastificationType.error);
                            }else{
                              cadastrar();
                            }
                          },
                          child: Text('Cadastrar', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat',)),
                          style: ElevatedButton.styleFrom(
                            elevation: 10.0,
                            backgroundColor: Color(0xFF212E38),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Voltar', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat',)),
                          style: ElevatedButton.styleFrom(
                            elevation: 10.0,
                            backgroundColor: Color(0xFF212E38),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF212E38),
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

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF212E38),
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
              color: Color(0xFF212E38),
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _dataNascimento == null ? '' : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
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
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (userCredential.user != null) {
        userCredential.user!.updateDisplayName(_nomeController.text);
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const checkPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Crie uma senha mais forte"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email já cadastrado"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
