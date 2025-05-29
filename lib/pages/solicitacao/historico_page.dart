import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart';

// Model class for Solicitacao (Request)
class Solicitacao {
  final String id;
  final String hospitalId;
  final String fornecedorId;
  final String fornecedorNome; // Stored for convenience
  final String instrumentalId;
  final String instrumentalNome;
  final int quantidade;
  final double valorUnitario;
  final double valorTotal;
  final String observacoes;
  final Timestamp? dataEntregaDesejada;
  final String status;
  final Timestamp dataSolicitacao;
  // Optional: Add fields for hospital name if needed for Fornecedor view
  // String? hospitalNome;

  Solicitacao({
    required this.id,
    required this.hospitalId,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.instrumentalId,
    required this.instrumentalNome,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.observacoes,
    this.dataEntregaDesejada,
    required this.status,
    required this.dataSolicitacao,
    // this.hospitalNome,
  });

  factory Solicitacao.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Solicitacao(
      id: doc.id,
      hospitalId: data['hospitalId'] ?? '',
      fornecedorId: data['fornecedorId'] ?? '',
      fornecedorNome: data['fornecedorNome'] ?? 'Nome Indisponível',
      instrumentalId: data['instrumentalId'] ?? '',
      instrumentalNome: data['instrumentalNome'] ?? 'Nome Indisponível',
      quantidade: (data['quantidade'] ?? 0).toInt(),
      valorUnitario: (data['valorUnitario'] ?? 0.0).toDouble(),
      valorTotal: (data['valorTotal'] ?? 0.0).toDouble(),
      observacoes: data['observacoes'] ?? '',
      dataEntregaDesejada: data['dataEntregaDesejada'] as Timestamp?,
      status: data['status'] ?? 'desconhecido',
      dataSolicitacao: data['dataSolicitacao'] ?? Timestamp.now(), // Provide default if null
    );
  }
}

class HistoricoSolicitacoesPage extends StatefulWidget {
  const HistoricoSolicitacoesPage({super.key});

  @override
  State<HistoricoSolicitacoesPage> createState() => _HistoricoSolicitacoesPageState();
}

class _HistoricoSolicitacoesPageState extends State<HistoricoSolicitacoesPage> {
  String? _userType;
  String? _userId;
  bool _isLoading = true;
  List<Solicitacao> _solicitacoes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchSolicitacoes();
  }

  Future<void> _loadUserDataAndFetchSolicitacoes() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  try {
    final prefs = await SharedPreferences.getInstance();
    _userId   = prefs.getString('usuarioId');
    _userType = prefs.getString('tipoUsuario');

    if (_userId == null || _userType == null) {
      throw Exception('Informações do usuário não encontradas.');
    }

    // 1) Carrega TODAS as solicitações
    final snapshot = await FirebaseFirestore.instance
        .collection('solicitacoesInstrumental')
        .get();

    // 2) Converte em lista de modelos
    final todas = snapshot.docs
        .map((doc) => Solicitacao.fromFirestore(doc))
        .toList();

    // 3) Filtra localmente conforme o tipo de usuário
    final filtradas = todas.where((s) {
      if (_userType == 'Hospital') {
        return s.hospitalId == _userId;
      } else {
        return s.fornecedorId == _userId;
      }
    }).toList();

    // 4) Ordena localmente pela data, mais recente primeiro
    filtradas.sort(
      (a, b) => b.dataSolicitacao.compareTo(a.dataSolicitacao),
    );

    if (!mounted) return;
    setState(() {
      _solicitacoes = filtradas;
      _isLoading    = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Erro ao carregar histórico: ${e.toString()}';
      _isLoading    = false;
    });
  }
}

  // Helper to format dates
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  // Helper to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange.shade700;
      case 'aprovada':
      case 'confirmada': // Assuming 'confirmada' is a possible status
        return Colors.green.shade700;
      case 'rejeitada':
      case 'cancelada':
        return Colors.red.shade700;
      case 'entregue':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkColor = Theme.of(context).primaryColorDark; // Example: Color(0xFF212E38)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Solicitações'),
        backgroundColor: primaryDarkColor,
        foregroundColor: const Color(0xFFF2E8C7), // Color for title and icons
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
          child: Text('Erro: $_errorMessage', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_solicitacoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhuma solicitação encontrada.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // Display the list of requests
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _solicitacoes.length,
      itemBuilder: (context, index) {
        final solicitacao = _solicitacoes[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(
              solicitacao.instrumentalNome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Show Fornecedor for Hospital, maybe Hospital for Fornecedor later
                if (_userType == 'Hospital')
                  Text('Fornecedor: ${solicitacao.fornecedorNome}'),
                // Add Hospital Name display here if fetched for Fornecedor view
                Text('Quantidade: ${solicitacao.quantidade}'),
                Text('Valor Total: R\$ ${solicitacao.valorTotal.toStringAsFixed(2)}'),
                Text('Data Solicitação: ${_formatTimestamp(solicitacao.dataSolicitacao)}'),
                if (solicitacao.dataEntregaDesejada != null)
                  Text('Entrega Desejada: ${_formatTimestamp(solicitacao.dataEntregaDesejada)}'),
                const SizedBox(height: 4),
                Text(
                  'Status: ${solicitacao.status.toUpperCase()}',
                  style: TextStyle(
                    color: _getStatusColor(solicitacao.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 if (solicitacao.observacoes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Obs: ${solicitacao.observacoes}', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
            // Optional: Add trailing icon or onTap for details
            // trailing: Icon(Icons.chevron_right),
            // onTap: () {
            //   // Navigate to detail page or show dialog
            // },
          ),
        );
      },
    );
  }
}

