import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInstrumental();
  }

  void _loadInstrumental() {
    _instrumentalFuture = Provider.of<InstrumentaisList>(context, listen: false)
        .buscarInstrumentalPorId(widget.instrumentalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Instrumental'),
        backgroundColor: const Color.fromARGB(255, 33, 46, 56),
        iconTheme: IconThemeData(color: Color(0xFFF2E8C7)),
      ),
      body: FutureBuilder<Instrumentais?>(
        future: _instrumentalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar os detalhes: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instrumental.nome,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('ID:', instrumental.id),
                        _buildInfoRow('Valor:', 'R\$ ${instrumental.valor.toStringAsFixed(2)}'),
                        _buildInfoRow('Quantidade disponível:', instrumental.contagem.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _showEditDialog(instrumental);
                              },
                              icon: Icon(Icons.edit),
                              label: Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(instrumental);
                              },
                              icon: Icon(Icons.delete),
                              label: Text('Excluir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
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
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Instrumentais instrumental) {
    final TextEditingController nomeController = TextEditingController(text: instrumental.nome);
    final TextEditingController valorController = TextEditingController(text: instrumental.valor.toString());
    final TextEditingController contagemController = TextEditingController(text: instrumental.contagem.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Instrumental'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: valorController,
                decoration: InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: contagemController,
                decoration: InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Implementar a lógica de atualização aqui
                // Por enquanto, apenas fechamos o diálogo
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Funcionalidade em implementação')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar: $e')),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Instrumentais instrumental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o instrumental ${instrumental.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Implementar a lógica de exclusão aqui
                // Por enquanto, apenas fechamos o diálogo e voltamos
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Funcionalidade em implementação')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir: $e')),
                );
              }
            },
            child: Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
