import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart'; // ou Fornecedor, conforme seu model

class ListaFornecedoresPage extends StatefulWidget {
  const ListaFornecedoresPage({super.key});

  @override
  State<ListaFornecedoresPage> createState() => _ListaFornecedoresPageState();
}

class _ListaFornecedoresPageState extends State<ListaFornecedoresPage> {
  bool _carregando = true;
  List<Usuario> _listaFornecedores = [];  // ou List<Fornecedor> se usar esse model
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarFornecedoresDoUsuarioAtual();
  }

  Future<void> _buscarFornecedoresDoUsuarioAtual() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _listaFornecedores = [];
    });

    try {
      // 1. Obter UID do usuário
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Usuário não autenticado.");
      }
      String currentUserUid = currentUser.uid;

      // 2. Ler doc do usuário atual
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();
      if (!userDoc.exists) {
        throw Exception("Documento do usuário atual não encontrado.");
      }

      // 3. Extrair lista de UIDs de fornecedores
      var userData = userDoc.data() as Map<String, dynamic>;
      List<String> fornecedoresUids = [];
      if (userData.containsKey('fornecedores') && userData['fornecedores'] is List) {
        fornecedoresUids = List<String>.from(
          (userData['fornecedores'] as List).map((e) => e.toString()),
        );
      }

      // 4. Se vazio, encerra
      if (fornecedoresUids.isEmpty) {
        setState(() {
          _listaFornecedores = [];
          _carregando = false;
        });
        return;
      }

      // 5. Buscar cada fornecedor individualmente
      List<Usuario> temp = [];
      for (var uid in fornecedoresUids) {
        try {
          var doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (doc.exists) {
            temp.add(Usuario.fromFirestore(doc));
          }
        } catch (e) {
          print("Erro ao buscar $uid: $e");
        }
      }

      // 6. Ordenar por nome
      temp.sort((a, b) => a.nome.compareTo(b.nome));

      setState(() {
        _listaFornecedores = temp;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = "Erro ao carregar fornecedores: ${e.toString()}";
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
        title: const Text('Lista de Fornecedores', style: TextStyle(color: Colors.white)),
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
    if (_listaFornecedores.isEmpty) {
      return const Center(child: Text('Nenhum fornecedor encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: _buscarFornecedoresDoUsuarioAtual,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _listaFornecedores.length,
        itemBuilder: (context, i) {
          final u = _listaFornecedores[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorDark.withOpacity(0.8),
                child: Text(
                  u.nome.isNotEmpty ? u.nome[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(u.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Text(u.email.isNotEmpty ? u.email : 'Email não informado'),
            ),
          );
        },
      ),
    );
  }
}
