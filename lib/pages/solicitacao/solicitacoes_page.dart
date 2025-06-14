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
    Solicitacao solicitacao,
    String novoStatus,
  ) async {
  bool proceed = true;
  // Confirmação para rejeição
  if (novoStatus == 'rejeitada') {
    proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar Rejeição'),
            content: const Text('Deseja realmente rejeitar esta solicitação?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Rejeitar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ==
        true;
  }
  if (!proceed) return;

  final firestore = FirebaseFirestore.instance;
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
    // Fluxo de ACEITAÇÃO: decrementa do fornecedor e incrementa no hospital
    if (novoStatus == 'confirmada') {
      final batch = firestore.batch();

      // 1) Decrementa contagem do fornecedor
      batch.update(fornecedorRef, {
        'contagem': FieldValue.increment(-solicitacao.quantidade),
      });

      // 2) Incrementa (ou cria) o instrumental no hospital
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

      // 3) Atualiza status da solicitação
      batch.update(solicitRef, {'status': novoStatus});

      await batch.commit();
    }
    // Fluxo de FINALIZAÇÃO: devolve para o fornecedor e remove do hospital
    else if (novoStatus == 'finalizada') {
      final batch = firestore.batch();

      // 1) Incrementa contagem do fornecedor
      batch.update(fornecedorRef, {
        'contagem': FieldValue.increment(solicitacao.quantidade),
      });

      // 2) Remove instrumental do hospital
      batch.delete(hospitalRef);

      // 3) Atualiza status da solicitação
      batch.update(solicitRef, {'status': novoStatus});

      await batch.commit();
    }
    // Fluxo de REJEIÇÃO ou outros status simples
    else {
      await solicitRef.update({'status': novoStatus});
    }

    // Atualiza a lista local e exibe feedback
    if (mounted) {
      setState(() {
        _pendentes.remove(solicitacao);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoStatus == 'confirmada'
                ? 'Solicitação aceita e estoques atualizados.'
                : novoStatus == 'finalizada'
                    ? 'Solicitação finalizada: estoque ajustado.'
                    : 'Solicitação $novoStatus com sucesso.',
          ),
          backgroundColor: novoStatus == 'confirmada' ||
                  novoStatus == 'finalizada'
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final Color primaryDarkColor = Theme.of(context).primaryColorDark;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações Pendentes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryDarkColor,
        foregroundColor: primaryColor,
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
                                Text('Descrição: ${s.observacoes}'),

                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          _updateStatus(s, 'confirmada'),
                                      child: const Text('Aceitar', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.green),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _updateStatus(s, 'rejeitada'),
                                      child: const Text('Recusar', style: TextStyle(color: Colors.white)),
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
