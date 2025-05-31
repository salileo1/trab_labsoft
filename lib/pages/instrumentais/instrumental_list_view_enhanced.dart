import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_add_modal.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_detail_view.dart';

class InstrumentaisListViewEnhanced extends StatefulWidget {
  final String? tipoStr; // parâmetro recebido

  const InstrumentaisListViewEnhanced({Key? key, this.tipoStr}) : super(key: key);

  @override
  _InstrumentaisListViewEnhancedState createState() =>
      _InstrumentaisListViewEnhancedState();
}

class _InstrumentaisListViewEnhancedState
    extends State<InstrumentaisListViewEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  List<Instrumentais> _instrumentais = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInstrumentais();
  }

  Future<void> _loadInstrumentais() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final instrumentaisList =
          Provider.of<InstrumentaisList>(context, listen: false);
      final instrumentais = await instrumentaisList.buscarTodosInstrumentais(1);

      setState(() {
        _instrumentais = instrumentais;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar instrumentais: $e';
        _isLoading = false;
      });
    }
  }

  List<Instrumentais> _getFilteredInstrumentais() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      return _instrumentais;
    }

    return _instrumentais.where((instrumental) {
      return instrumental.nome.toLowerCase().contains(searchTerm) ||
          instrumental.id.toLowerCase().contains(searchTerm);
    }).toList();
  }

  void _showAddInstrumentalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CadInstrumentalForm(
            onSubmit: _handleSubmit,
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit(InstrumentaisFormData formData) async {
    try {
      await Provider.of<InstrumentaisList>(context, listen: false)
          .cadastrarInstrumentais(
              formData.nome, formData.valor, formData.contagem, context);

      // Recarregar a lista após adicionar
      _loadInstrumentais();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrumental cadastrado com sucesso!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar instrumental: $error')),
      );
    }
  }

  void _navigateToDetailView(Instrumentais instrumental) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstrumentalDetailView(
          instrumentalId: instrumental.id,
        ),
      ),
    ).then((_) {
      // Recarregar a lista quando voltar da tela de detalhes
      _loadInstrumentais();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredInstrumentais = _getFilteredInstrumentais();

    return Scaffold(
      // Fundo branco
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Instrumentais', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green, // AppBar verde
        iconTheme: const IconThemeData(color: Colors.white), // ícones brancos
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstrumentais,
            tooltip: 'Atualizar lista',
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca com borda arredondada
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar instrumentais',
                hintText: 'Digite o nome ou ID do instrumental',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Lista propriamente dita
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filteredInstrumentais.isEmpty
                        ? const Center(
                            child: Text('Nenhum instrumental encontrado'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: filteredInstrumentais.length,
                            itemBuilder: (context, index) {
                              final instrumental = filteredInstrumentais[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  title: Text(
                                    instrumental.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Valor: R\$ ${instrumental.valor.toStringAsFixed(2)}  •  Quantidade: ${instrumental.contagem}',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.green,
                                  ),
                                  onTap: () =>
                                      _navigateToDetailView(instrumental),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      // FAB verde para Fornecedor
      floatingActionButton: widget.tipoStr == 'Fornecedor'
          ? FloatingActionButton(
              onPressed: _showAddInstrumentalModal,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Adicionar Instrumental',
            )
          : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
