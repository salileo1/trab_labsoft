import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/pages/solicitacao/historico_page.dart';


class SolicitacoesPendentesPage extends StatefulWidget {
  const SolicitacoesPendentesPage({Key? key}) : super(key: key);

  @override
  _SolicitacoesPendentesPageState createState() => _SolicitacoesPendentesPageState();
}

class _SolicitacoesPendentesPageState extends State<SolicitacoesPendentesPage> {
  String? _userId;
  bool _isLoading = true;
  List<Solicitacao> _pendentes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSolicitacoesPendentes();
  }

 Future<void> _loadSolicitacoesPendentes() async {
  setState(() {
    _isLoading   = true;
    _errorMessage = null;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('usuarioId');
    if (_userId == null) throw Exception('Usuário não autenticado.');

    // 1) Buscar apenas por hospitalId (índice simples padrão)
    final snapshot = await FirebaseFirestore.instance
        .collection('solicitacoesInstrumental')
        .where('fornecedorId', isEqualTo: _userId)
        .get();

    // 2) Converter e filtrar localmente status == 'pendente'
    final lista = snapshot.docs
        .map((doc) => Solicitacao.fromFirestore(doc))
        .where((s) => s.status == 'pendente')
        .toList();

    // 3) Ordenar localmente por dataSolicitacao (mais recente primeiro)
    lista.sort((a, b) => b.dataSolicitacao.compareTo(a.dataSolicitacao));

    if (!mounted) return;
    setState(() {
      _pendentes = lista;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Erro: ${e.toString()}';
      _isLoading    = false;
    });
  }
}


  String _formatTimestamp(Timestamp ts) =>
      DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());

  Future<void> _updateStatus(
      Solicitacao solicitacao, String novoStatus) async {
    bool proceed = true;
    if (novoStatus == 'rejeitada') {
      proceed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirmar Rejeição'),
              content: const Text(
                  'Deseja realmente rejeitar esta solicitação?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Rejeitar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ) ==
          true;
    }

    if (!proceed) return;

    try {
      await FirebaseFirestore.instance
          .collection('solicitacoesInstrumental')
          .doc(solicitacao.id)
          .update({'status': novoStatus});

      setState(() {
        _pendentes.remove(solicitacao);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Solicitação ${novoStatus == 'confirmada' ? 'aceita' : 'rejeitada'} com sucesso.'),
          backgroundColor:
              novoStatus == 'confirmada' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações Pendentes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _pendentes.isEmpty
                  ? const Center(child: Text('Sem solicitações pendentes.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _pendentes.length,
                      itemBuilder: (context, i) {
                        final s = _pendentes[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.instrumentalNome,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Quantidade: ${s.quantidade}'),
                                Text('Valor Total: R\$ ${s.valorTotal.toStringAsFixed(2)}'),
                                Text('Data: ${_formatTimestamp(s.dataSolicitacao)}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          _updateStatus(s, 'confirmada'),
                                      child: const Text('Aceitar'),
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.green),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _updateStatus(s, 'rejeitada'),
                                      child: const Text('Recusar'),
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.red),
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
