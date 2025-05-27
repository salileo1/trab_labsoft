import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FornecedorAdesaoForm extends StatefulWidget {
  const FornecedorAdesaoForm({Key? key}) : super(key: key);

  @override
  _FornecedorAdesaoFormState createState() => _FornecedorAdesaoFormState();
}

class _FornecedorAdesaoFormState extends State<FornecedorAdesaoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeHospitalController = TextEditingController();
  final _cnpjHospitalController = TextEditingController();
  final _motivoController = TextEditingController();
  final _contatoController = TextEditingController();
  bool _isLoading = false;
  List<String> _hospitais = [];
  String? _selectedHospital;

  @override
  void initState() {
    super.initState();
    _carregarHospitais();
  }

  Future<void> _carregarHospitais() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulação de carregamento de hospitais
      // Em uma implementação real, isso viria do Firestore
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _hospitais = [
          'Hospital São Lucas',
          'Hospital Albert Einstein',
          'Hospital Sírio-Libanês',
          'Hospital Santa Catarina',
          'Hospital Oswaldo Cruz',
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar hospitais: $e')),
      );
    }
  }

  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obter o ID do fornecedor atual (usuário logado)
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Criar dados da solicitação
      final solicitacaoData = {
        'fornecedorId': userId,
        'hospitalNome': _selectedHospital ?? _nomeHospitalController.text,
        'cnpjHospital': _cnpjHospitalController.text,
        'motivo': _motivoController.text,
        'contato': _contatoController.text,
        'status': 'pendente',
        'dataSolicitacao': FieldValue.serverTimestamp(),
      };

      // Em uma implementação real, salvaríamos no Firestore
      // await FirebaseFirestore.instance.collection('solicitacoesAdesao').add(solicitacaoData);
      
      // Simulação de envio bem-sucedido
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação enviada com sucesso!')),
      );

      // Limpar formulário
      _formKey.currentState!.reset();
      _nomeHospitalController.clear();
      _cnpjHospitalController.clear();
      _motivoController.clear();
      _contatoController.clear();
      setState(() {
        _selectedHospital = null;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar solicitação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar Adesão a Hospital'),
        backgroundColor: const Color.fromARGB(255, 33, 46, 56),
        iconTheme: IconThemeData(color: Color(0xFFF2E8C7)),
      ),
      body: _isLoading && _hospitais.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecione um Hospital',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedHospital,
                              decoration: InputDecoration(
                                labelText: 'Hospital',
                                border: OutlineInputBorder(),
                              ),
                              items: _hospitais.map((hospital) {
                                return DropdownMenuItem(
                                  value: hospital,
                                  child: Text(hospital),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedHospital = value;
                                });
                              },
                              validator: (value) {
                                if (_selectedHospital == null && _nomeHospitalController.text.isEmpty) {
                                  return 'Selecione um hospital ou informe um novo';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Ou informe um novo hospital',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _nomeHospitalController,
                              decoration: InputDecoration(
                                labelText: 'Nome do Hospital',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _cnpjHospitalController,
                              decoration: InputDecoration(
                                labelText: 'CNPJ do Hospital',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_selectedHospital == null && (value == null || value.isEmpty)) {
                                  return 'Informe o CNPJ do hospital';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações da Solicitação',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _motivoController,
                              decoration: InputDecoration(
                                labelText: 'Motivo da Solicitação',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o motivo da solicitação';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _contatoController,
                              decoration: InputDecoration(
                                labelText: 'Contato para Comunicação',
                                border: OutlineInputBorder(),
                                hintText: 'Email ou telefone',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe um contato';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _enviarSolicitacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF466B66),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Enviar Solicitação',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeHospitalController.dispose();
    _cnpjHospitalController.dispose();
    _motivoController.dispose();
    _contatoController.dispose();
    super.dispose();
  }
}
