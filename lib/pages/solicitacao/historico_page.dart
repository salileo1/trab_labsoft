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
  String status; // Made non-final to allow local update after change
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
      status: data['status']?.toLowerCase() ?? 'desconhecido', // Ensure status is lowercase
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

  // Define possible statuses and terminal statuses
  final List<String> _statusOptions = ['pendente', 'confirmada', 'rejeitada', 'finalizada'];
  final List<String> _terminalStatuses = ['rejeitada', 'finalizada'];

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


  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange.shade700;
      case 'confirmada':
        return Colors.green.shade700;
      case 'rejeitada':
      case 'cancelada':
        return Colors.red.shade700;
      case 'finalizada':
        return Colors.purple.shade700; // Changed color for delivered
      default:
        return Colors.grey.shade600;
    }
  }

 Future<void> _updateStatus(
  Solicitacao solicitacao,
  String newStatus,
) async {
  final statusLower = newStatus.toLowerCase();

  // 1) Se for status terminal, pedir confirmação
  if (_terminalStatuses.contains(statusLower)) {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Status: ${newStatus.toUpperCase()}'),
        content: Text(
          'Tem certeza que deseja definir o status como '
          '"${newStatus.toUpperCase()}"? Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Confirmar',
              style: TextStyle(color: _getStatusColor(statusLower)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
  }

  final firestore  = FirebaseFirestore.instance;
  final solicitRef = firestore
      .collection('solicitacoesInstrumental')
      .doc(solicitacao.id);

  final fornecedorRef = firestore
      .collection('users')
      .doc(solicitacao.fornecedorId)
      .collection('instrumentais')
      .doc(solicitacao.instrumentalId);

  final hospitalRef = firestore
      .collection('users')
      .doc(solicitacao.hospitalId)
      .collection('instrumentais')
      .doc(solicitacao.instrumentalId);

  try {
    // 2) Se for CONFIRMADA: decrementa do fornecedor e incrementa no hospital
    if (statusLower == 'confirmada') {
      final batch = firestore.batch();

      batch.update(fornecedorRef, {
        'contagem': FieldValue.increment(-solicitacao.quantidade),
      });

      batch.set(
        hospitalRef,
        {
          'id':       solicitacao.instrumentalId,
          'nome':     solicitacao.instrumentalNome,
          'valor':    solicitacao.valorUnitario,
          'contagem': FieldValue.increment(solicitacao.quantidade),
        },
        SetOptions(merge: true),
      );

      batch.update(solicitRef, {'status': statusLower});
      await batch.commit();
    }
    // 3) Se for FINALIZADA: reverte no fornecedor e remove do hospital
    else if (statusLower == 'finalizada') {
      final batch = firestore.batch();

      batch.update(fornecedorRef, {
        'contagem': FieldValue.increment(solicitacao.quantidade),
      });

      batch.delete(hospitalRef);

      batch.update(solicitRef, {'status': statusLower});
      await batch.commit();
    }
    // 4) Para REJEITADA ou outros status simples
    else {
      await solicitRef.update({'status': statusLower});
    }

    // 5) Atualiza apenas o campo local de status
    if (mounted) {
      setState(() {
        solicitacao.status = statusLower;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            statusLower == 'confirmada'
                ? 'Solicitação aceita e estoques atualizados.'
                : statusLower == 'finalizada'
                    ? 'Solicitação finalizada: estoque revertido e instrumento removido.'
                    : 'Status atualizado para ${newStatus.toUpperCase()}.',
          ),
          backgroundColor:
              (statusLower == 'confirmada' || statusLower == 'finalizada')
                  ? Colors.green
                  : Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final Color primaryDarkColor = Theme.of(context).primaryColorDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Solicitações'),
        backgroundColor: primaryDarkColor,
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
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

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _solicitacoes.length,
      itemBuilder: (context, index) {
        final solicitacao = _solicitacoes[index];
        final bool isTerminal = _terminalStatuses.contains(solicitacao.status);
        final bool canChangeStatus = _userType == 'Fornecedor' && !isTerminal;

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
                  solicitacao.instrumentalNome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                if (_userType == 'Hospital')
                  Text('Fornecedor: ${solicitacao.fornecedorNome}'),
                // TODO: Add Hospital Name display here if needed for Fornecedor view
                Text('Quantidade: ${solicitacao.quantidade}'),
                Text('Valor Total: R\$ ${solicitacao.valorTotal.toStringAsFixed(2)}'),
                Text('Data Solicitação: ${_formatTimestamp(solicitacao.dataSolicitacao)}'),
                if (solicitacao.dataEntregaDesejada != null)
                  Text('Entrega Desejada: ${_formatTimestamp(solicitacao.dataEntregaDesejada)}'),
                if (solicitacao.observacoes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Obs: ${solicitacao.observacoes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 8),
                // Status Display and Change Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Current Status Display
                    Chip(
                      label: Text(
                        solicitacao.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _getStatusColor(solicitacao.status),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                    // Status Change Dropdown (only for Fornecedor and non-terminal status)
                    if (canChangeStatus)
                      DropdownButton<String>(
                        value: solicitacao.status, // Current status
                        icon: const Icon(Icons.edit, size: 18),
                        underline: Container(), // Remove default underline
                        items: _statusOptions.map((String statusValue) {
                          return DropdownMenuItem<String>(
                            value: statusValue,
                            child: Text(statusValue.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newStatus) {
                          if (newStatus != null && newStatus != solicitacao.status) {
                            _updateStatus(solicitacao, newStatus);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

