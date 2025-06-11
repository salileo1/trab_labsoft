import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart'; // seu model Usuario

class ListaHospitaisPage extends StatefulWidget {
  const ListaHospitaisPage({super.key});

  @override
  State<ListaHospitaisPage> createState() => _ListaHospitaisPageState();
}

class _ListaHospitaisPageState extends State<ListaHospitaisPage> {
  bool _carregando = true;
  List<Usuario> _listaHospitais = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarHospitaisDoFornecedorAtual();
  }

  Future<void> _buscarHospitaisDoFornecedorAtual() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _listaHospitais = [];
    });

    try {
      // 1. UID do fornecedor (usuário atual)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não autenticado.");
      final fornecedorUid = user.uid;

      // 2. Consulta hospitais cujo array 'fornecedores' contém este UID
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .where('tipoUsuario', isEqualTo: 'Hospital')
          .where('fornecedores', arrayContains: fornecedorUid)
          .get();

      // 3. Converte em Usuario e ordena por nome
      final hospitais = qs.docs
          .map((doc) => Usuario.fromFirestore(doc))
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

      setState(() {
        _listaHospitais = hospitais;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = "Erro ao carregar hospitais: ${e.toString()}";
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryDark = Theme.of(context).primaryColorDark;
    final primary    = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitais Vinculados', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryDark,
        foregroundColor: primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)));
    }
    if (_listaHospitais.isEmpty) {
      return const Center(child: Text('Você não pertence a nenhum hospital.'));
    }

    return RefreshIndicator(
      onRefresh: _buscarHospitaisDoFornecedorAtual,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _listaHospitais.length,
        itemBuilder: (context, i) {
          final hosp = _listaHospitais[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorDark.withOpacity(0.8),
                child: Text(
                  hosp.nome.isNotEmpty ? hosp.nome[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(hosp.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Text(hosp.email.isNotEmpty ? hosp.email : 'E-mail não informado'),
            ),
          );
        },
      ),
    );
  }
}
