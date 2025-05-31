import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart'; // Usuário com fromFirestore

class ListaFornecedoresPage extends StatefulWidget {
  const ListaFornecedoresPage({super.key});

  @override
  State<ListaFornecedoresPage> createState() => _ListaFornecedoresPageState();
}

class _ListaFornecedoresPageState extends State<ListaFornecedoresPage> {
  bool _isLoading = true;
  List<Usuario> _fornecedores = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFornecedores();
  }

  Future<void> _fetchFornecedores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fornecedores = []; // Limpa a lista anterior
    });
    try {
      // 1) Buscar apenas por tipoUsuario == 'Fornecedor' (sem orderBy)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('tipoUsuario', isEqualTo: 'Fornecedor')
          .get();

      // 2) Converter cada documento em Usuario
      final fornecedoresData = querySnapshot.docs
          .map((doc) => Usuario.fromFirestore(doc))
          .toList();

      // 3) Ordenar localmente pelo campo 'nome'
      fornecedoresData.sort((a, b) => a.nome.compareTo(b.nome));

      if (mounted) {
        setState(() {
          _fornecedores = fornecedoresData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar fornecedores: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar fornecedores: ${e.toString()}';
          _isLoading = false;
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
        title: const Text('Lista de Fornecedores', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryDarkColor,
        foregroundColor: primaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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

    if (_fornecedores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhum fornecedor encontrado.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Exibe a lista de fornecedores
    return RefreshIndicator(
      onRefresh: _fetchFornecedores, // Permite pull-to-refresh
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _fornecedores.length,
        itemBuilder: (context, index) {
          final fornecedor = _fornecedores[index];
          return Card(
            elevation: 2,
            margin:
                const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColorDark.withOpacity(0.8),
                child: Text(
                  fornecedor.nome.isNotEmpty
                      ? fornecedor.nome[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                fornecedor.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 16),
              ),
              subtitle: Text(fornecedor.email ?? 'Email não informado'),
            ),
          );
        },
      ),
    );
  }
}
