import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/pages/adesao/adesao_request.dart';

class ListaSolicitacoesAdesaoPage extends StatefulWidget {
  const ListaSolicitacoesAdesaoPage({super.key});

  @override
  State<ListaSolicitacoesAdesaoPage> createState() => _ListaSolicitacoesAdesaoPageState();
}

class _ListaSolicitacoesAdesaoPageState extends State<ListaSolicitacoesAdesaoPage> {
  String? _userType;
  String? _userId;
  bool _isLoading = true;
  List<AdesaoRequest> _solicitacoesPendentes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchPendentes();
  }

 Future<void> _loadUserDataAndFetchPendentes() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _solicitacoesPendentes = [];
  });
  try {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('usuarioId');
    _userType = prefs.getString('tipoUsuario');

    if (_userId == null || _userType == null) {
      throw Exception('Informações do usuário não encontradas.');
    }

    if (_userType != 'Hospital') {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Acesso restrito a hospitais.';
      });
      return;
    }

    // 1) Buscando apenas pelo hospitalId (índice simples padrão)
    final querySnapshot = await FirebaseFirestore.instance
        .collection('adesaoRequests')
        .where('hospitalId', isEqualTo: _userId)
        .get();

    // 2) Converter em lista de AdesaoRequest e filtrar localmente status == 'pendente'
    final todos = querySnapshot.docs
        .map((doc) => AdesaoRequest.fromFirestore(doc))
        .where((req) => req.status == 'pendente')
        .toList();

    // 3) Ordenar localmente pelo campo requestTimestamp (mais antigo primeiro)
    todos.sort((a, b) =>
        a.requestTimestamp.compareTo(b.requestTimestamp));

    if (!mounted) return;
    setState(() {
      _solicitacoesPendentes = todos;
      _isLoading = false;
    });
  } catch (e) {
    print('Erro ao buscar solicitações de adesão pendentes: $e');
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Erro ao carregar solicitações: ${e.toString()}';
      _isLoading = false;
    });
  }
}


  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  // --- Action Logic ---
  Future<void> _handleAdesaoRequest(AdesaoRequest request, bool accept) async {
    final newStatus = accept ? 'aceita' : 'rejeitada';
    final requestId = request.id;
    final fornecedorId = request.fornecedorId;

    // Optimistically update UI by removing the item
    setState(() {
      _solicitacoesPendentes.removeWhere((r) => r.id == requestId);
    });

    try {
      // 1. Update the status of the AdesaoRequest document
      await FirebaseFirestore.instance
          .collection('adesaoRequests')
          .doc(requestId)
          .update({'status': newStatus});

      // 2. If accepted, update the hospital's 'fornecedores' list
      if (accept && _userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({
          'fornecedores': FieldValue.arrayUnion([fornecedorId])
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação ${accept ? 'Aceita' : 'Recusada'} com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Erro ao ${accept ? 'aceitar' : 'recusar'} solicitação $requestId: $e');
      // Revert UI change is complex, better to show error and prompt refresh
      // Or simply re-fetch the list after error
      setState(() {
         _errorMessage = 'Erro ao processar solicitação. Tente novamente.';
         // Optionally re-add the item to the list or trigger a refresh
         // _loadUserDataAndFetchPendentes(); // Re-fetch to ensure consistency
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao ${accept ? 'aceitar' : 'recusar'} solicitação: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkColor = Theme.of(context).primaryColorDark;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Adesão', style: TextStyle(color: Colors.white)),
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
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    if (_solicitacoesPendentes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhuma solicitação de adesão pendente encontrada.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserDataAndFetchPendentes, // Allow pull-to-refresh
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _solicitacoesPendentes.length,
        itemBuilder: (context, index) {
          final request = _solicitacoesPendentes[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fornecedor: ${request.fornecedorNome}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('Solicitado em: ${_formatTimestamp(request.requestTimestamp)}'),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Recusar', style: TextStyle(color: Colors.red)),
                        onPressed: () => _handleAdesaoRequest(request, false),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aceitar'),
                        onPressed: () => _handleAdesaoRequest(request, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

