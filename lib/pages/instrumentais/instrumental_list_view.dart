import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_add_modal.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_item.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_page.dart';

class InstrumentaisListViewPage extends StatefulWidget {
  const InstrumentaisListViewPage({Key? key}) : super(key: key);

  @override
  InstrumentalListViewPage createState() => InstrumentalListViewPage();
}

class InstrumentalListViewPage extends State<InstrumentaisListViewPage> {
  TextEditingController _searchController = TextEditingController();

  List<Instrumentais> _tarefas = [];

  @override
  Widget build(BuildContext context) {
    final instrumentaisList = Provider.of<InstrumentaisList>(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Row(
                                children: [
                                  Text(
                                    'Instrumentais:',
                                    style: TextStyle(
                                      fontSize: 30,
                                    ),
                                  ),
                                  Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CadInstrumentalForm(
                                            onSubmit: _handleSubmit,
                                          );
                                        },
                                      );
                                    },
                                    child: Text(
                                      "Adicionar instrumental",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF212E38),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Buscar instrumentais',
                                hintText: 'Digite o nome do instrumental',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  // Atualiza o filtro quando o texto mudar
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FutureBuilder<List<Instrumentais>>(
                            future: instrumentaisList.buscarTodosInstrumentais(1),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Erro ao carregar os instrumentais'),
                                );
                              } else {
                                _tarefas = snapshot.data ?? [];
                                if (_tarefas.isEmpty) {
                                  return Center(
                                    child: Text('Nenhum instrumental encontrado'),
                                  );
                                } else {
                                  // Filtrar os produtos com base na busca
                                  List<Instrumentais> instrumentaisFiltrados =
                                      _tarefas.where((instrumental) {
                                    String searchTerm =
                                        _searchController.text.toLowerCase();
                                    return instrumental.nome
                                        .toLowerCase()
                                        .contains(searchTerm);
                                  }).toList();

                                  return ListView.separated(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: instrumentaisFiltrados.length,
                                    separatorBuilder:
                                        (BuildContext context, int index) {
                                      return Divider(); // Adiciona um Divider entre cada item
                                    },
                                    itemBuilder: (ctx, i) {
                                      final instrumental = instrumentaisFiltrados[i];
                                      return instrumentalItem(
                                        instrumental: instrumental,
                                      );
                                    },
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleSubmit(InstrumentaisFormData formData) async {
    try {
      await Provider.of<InstrumentaisList>(context, listen: false).cadastrarInstrumentais(formData.nome, formData.valor, formData.contagem, context);
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: Text('Ocorreu um erro ao cadastrar: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      if (!mounted) return;
    }
  }
}

class EditarProdutoDialog extends StatefulWidget {
  final Instrumentais instrumental;
  final Function(double) onSalvar;

  const EditarProdutoDialog({required this.instrumental, required this.onSalvar, Key? key}) : super(key: key);

  @override
  _EditarProdutoDialogState createState() => _EditarProdutoDialogState();
}

class _EditarProdutoDialogState extends State<EditarProdutoDialog> {
  late TextEditingController _valorController;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(text: widget.instrumental.valor.toString());
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Produto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Valor',
              hintText: 'Digite o novo valor',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final novoValor = double.tryParse(_valorController.text);
            if (novoValor != null) {
              widget.onSalvar(novoValor);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Por favor, insira um valor válido'),
              ));
            }
          },
          child: Text('Salvar'),
        ),
      ],
    );
  }
}

