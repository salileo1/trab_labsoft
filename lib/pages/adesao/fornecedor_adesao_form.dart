import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart';
import 'package:trab_labsoft/pages/adesao/adesao_request.dart'; // For hospital data

class SolicitacaoAdesaoPage extends StatefulWidget {
  const SolicitacaoAdesaoPage({super.key});

  @override
  State<SolicitacaoAdesaoPage> createState() => _SolicitacaoAdesaoPageState();
}

class _SolicitacaoAdesaoPageState extends State<SolicitacaoAdesaoPage> {
  String? _fornecedorId;
  String? _fornecedorNome;
  bool _isLoadingHospitais = true;
  bool _isSendingRequest = false;
  List<Usuario> _hospitais = [];
  Usuario? _selectedHospital;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFornecedorDataAndFetchHospitais();
  }

  Future<void> _loadFornecedorDataAndFetchHospitais() async {
    setState(() {
      _isLoadingHospitais = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _fornecedorId = prefs.getString('usuarioId');
      _fornecedorNome = prefs.getString('usuarioNome');

      if (_fornecedorId == null || _fornecedorNome == null) {
        throw Exception('Informações do fornecedor não encontradas.');
      }

      // 1) Buscar apenas pelo tipoUsuario == 'Hospital' (sem orderBy)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('tipoUsuario', isEqualTo: 'Hospital')
          .get();

      // 2) Converter cada document em Usuario
      final hospitaisData = querySnapshot.docs.map((doc) {
        return Usuario.fromFirestore(doc);
      }).toList();

      // 3) Ordenar localmente pelo campo nome
      hospitaisData.sort((a, b) => a.nome.compareTo(b.nome));

      if (mounted) {
        setState(() {
          _hospitais = hospitaisData;
          _isLoadingHospitais = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar hospitais: ${e.toString()}';
          _isLoadingHospitais = false;
        });
      }
    }
  }

  Future<void> _enviarSolicitacao() async {
    if (_selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um hospital.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_fornecedorId == null || _fornecedorNome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Informações do fornecedor não encontradas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingRequest = true;
    });

    try {
      // 1) Verificar se já existe pedido pendente
      final existingRequest = await FirebaseFirestore.instance
          .collection('adesaoRequests')
          .where('fornecedorId', isEqualTo: _fornecedorId)
          .where('hospitalId', isEqualTo: _selectedHospital!.id)
          .where('status', isEqualTo: 'pendente')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Já existe uma solicitação pendente para este hospital.');
      }

      // 2) Verificar se já está associado (campo 'fornecedores' do hospital)
      final hospitalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedHospital!.id)
          .get();
      final hospitalData = hospitalDoc.data();
      if (hospitalData != null &&
          hospitalData.containsKey('fornecedores') &&
          hospitalData['fornecedores'] is List) {
        List<dynamic> fornecedoresList = hospitalData['fornecedores'];
        if (fornecedoresList.contains(_fornecedorId)) {
          throw Exception('Você já está associado a este hospital.');
        }
      }

      // 3) Criar e salvar novo AdesaoRequest
      final newRequest = AdesaoRequest(
        id: '', // Firestore gerará o ID
        fornecedorId: _fornecedorId!,
        fornecedorNome: _fornecedorNome!,
        hospitalId: _selectedHospital!.id,
        status: 'pendente',
        requestTimestamp: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('adesaoRequests')
          .add(newRequest.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação de adesão enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedHospital = null;
        });
      }
    } catch (e) {
      print('Erro ao enviar solicitação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkColor = Theme.of(context).primaryColorDark;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Adesão a Hospital', style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryDarkColor,
        foregroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingHospitais) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_hospitais.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhum hospital encontrado para solicitar adesão.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecione o Hospital:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Usuario>(
          value: _selectedHospital,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Hospital',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Selecione...'),
          items: _hospitais.map((Usuario hospital) {
            return DropdownMenuItem<Usuario>(
              value: hospital,
              child: Text(hospital.nome, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (Usuario? newValue) {
            setState(() {
              _selectedHospital = newValue;
            });
          },
          validator: (value) => value == null ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: _isSendingRequest
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.send, color: Colors.white,),
          label: Text(_isSendingRequest
              ? 'Enviando...'
              : 'Enviar Solicitação', style: TextStyle(color: Colors.white)),
          onPressed: _isSendingRequest ? null : _enviarSolicitacao,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColorDark,
            foregroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
