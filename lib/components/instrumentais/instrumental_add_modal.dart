import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';

class CadInstrumentalForm extends StatefulWidget {
  final void Function(InstrumentaisFormData) onSubmit;

  const CadInstrumentalForm({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CadInstrumentalForm> createState() => _CadInstrumentalFormState();
}

class _CadInstrumentalFormState extends State<CadInstrumentalForm> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final _formData = InstrumentaisFormData(
    id: '',
    nome: '',
    valor: 0.0,
    contagem: 0,
  );
  dynamic _user;

  String idCliente = '';
  late DocumentReference clienteDoc;

  late List<String> setorOptions = [];
  String? _selectedSetor;

  @override
  void initState() {
    super.initState();
  }

  String generateUID() {
    Random random = Random();
    String uid = '';
    for (int i = 0; i < 4; i++) {
      uid += random.nextInt(10).toString();
    }
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo "Nome"
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Nome",
                    style: TextStyle(
                      color: Color(0xFF466B66),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('nome'),
                  initialValue: _formData.nome,
                  onChanged: (nome) => _formData.nome = nome,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),  
                ),

                // Campo "Valor"
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Valor",
                    style: TextStyle(
                      color: Color(0xFF466B66),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('valor'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (valor) {
                    _formData.valor = double.tryParse(valor) ?? 0.0;
                  },
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),  
                ),

                // Novo campo "Quantidade"
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Quantidade",
                    style: TextStyle(
                      color: Color(0xFF466B66),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('quantidade'),
                  keyboardType: TextInputType.number,
                  onChanged: (qtde) {
                    _formData.contagem = int.tryParse(qtde) ?? 0;
                  },
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),  
                ),

                const SizedBox(height: 24),

                // Botão "Salvar"
                ElevatedButton(
                  onPressed: () async {
                    try {
                      String uid = generateUID();

                      // Obtenha o ID do usuário atual (se precisar salvar em Firestore)
                      String? userId =
                          FirebaseAuth.instance.currentUser?.uid;

                      InstrumentaisFormData formData = InstrumentaisFormData(
                        id: uid,
                        nome: _formData.nome,
                        valor: _formData.valor,
                        contagem: _formData.contagem,
                      );
                      // Submeta os dados
                      widget.onSubmit(formData);

                      // Feche o formulário
                      Navigator.pop(context);
                    } catch (error) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Erro'),
                            content: Text('Ocorreu um erro ao cadastrar: $error'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Salvar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    elevation: 10.0,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
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
    );
  }
}
