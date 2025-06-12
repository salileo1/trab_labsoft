import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';

class InstrumentalDetailView extends StatefulWidget {
  final String instrumentalId;

  const InstrumentalDetailView({
    Key? key,
    required this.instrumentalId,
  }) : super(key: key);

  @override
  _InstrumentalDetailViewState createState() => _InstrumentalDetailViewState();
}

class _InstrumentalDetailViewState extends State<InstrumentalDetailView> {
  late Future<Instrumentais?> _instrumentalFuture;
  final Color _primaryGreen = Colors.green.shade700;
  String? tipoStr;


  @override
  void initState() {
    super.initState();
    _loadInstrumental();

    const duration = Duration(milliseconds: 300);
    Future.delayed(duration, () async {
      final prefs = await SharedPreferences.getInstance();
      final storedTipo = prefs.getString('tipoUsuario');
      setState(() {
        tipoStr = storedTipo;
      });
    });
  }

  void _loadInstrumental() {
    _instrumentalFuture = Provider.of<InstrumentaisList>(context, listen: false)
        .buscarInstrumentalPorId(widget.instrumentalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detalhes do Instrumental',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: FutureBuilder<Instrumentais?>(
        future: _instrumentalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar os detalhes: \${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Instrumental não encontrado'),
            );
          }

          final instrumental = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instrumental.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('ID:', instrumental.id),
                        _buildInfoRow('Valor:', 'R\$${instrumental.valor.toStringAsFixed(2)}'),
                        _buildInfoRow('Quantidade disponível:', instrumental.contagem.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if(tipoStr == 'Fornecedor')
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(instrumental),
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showDeleteConfirmation(instrumental),
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text('Excluir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Instrumentais instrumental) {
    final nomeController = TextEditingController(text: instrumental.nome);
    final valorController = TextEditingController(text: instrumental.valor.toString());
    final contagemController = TextEditingController(text: instrumental.contagem.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Instrumental'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: valorController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: contagemController,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final novoNome = nomeController.text;
              final novoValor = double.tryParse(valorController.text) ?? 0.0;
              final novaContagem = int.tryParse(contagemController.text) ?? 0;

              try {
                await Provider.of<InstrumentaisList>(context, listen: false)
                    .atualizarInstrumental(
                      instrumental.id,
                      novoNome,
                      novoValor,
                      novaContagem,
                    );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Instrumental atualizado!')),
                );
                _loadInstrumental();
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar: \$e')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Instrumentais instrumental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o instrumental "\${instrumental.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<InstrumentaisList>(context, listen: false)
                    .removerInstrumental(instrumental.id);

                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Instrumental removido!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir: \$e')),
                );
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
