import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para representar um Instrumental
class Instrumentais {
  final String id;
  final String nome;
  final double valor;
  final int contagem; // Assumindo que 'contagem' é um inteiro
  final String fornecedorUid;

  Instrumentais({
    required this.id,
    required this.nome,
    required this.valor,
    required this.contagem,
    required this.fornecedorUid,
  });

  // Construtor factory para criar a partir de um DocumentSnapshot
  factory Instrumentais.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Instrumentais(
      id: doc.id,
      nome: data['nome'] ?? 'Nome Indisponível',
      // Tratamento cuidadoso para valor e contagem, podem ser int ou double no Firestore
      valor: (data['valor'] ?? 0.0).toDouble(), 
      contagem: (data['contagem'] ?? 0).toInt(),
      fornecedorUid: data['fornecedorUid'] ?? '',
    );
  }
}

class ListaInstrumentaisFornecedor extends StatefulWidget {
  final String? fornecedorUid; // UID do fornecedor selecionado (pode ser nulo)
  final Function(Instrumentais?) onInstrumentalSelecionado;

  const ListaInstrumentaisFornecedor({
    Key? key,
    required this.fornecedorUid,
    required this.onInstrumentalSelecionado,
  }) : super(key: key);

  @override
  _ListaInstrumentaisFornecedorState createState() => _ListaInstrumentaisFornecedorState();
}

class _ListaInstrumentaisFornecedorState extends State<ListaInstrumentaisFornecedor> {
  List<Instrumentais> _instrumentaisDisponiveis = [];
  Instrumentais? _selectedInstrumental;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Busca inicial se já houver um fornecedor selecionado
    if (widget.fornecedorUid != null) {
      _buscarInstrumentais(widget.fornecedorUid!);
    }
  }

  @override
  void didUpdateWidget(covariant ListaInstrumentaisFornecedor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verifica se o fornecedorUid mudou e não é nulo
    if (widget.fornecedorUid != oldWidget.fornecedorUid) {
       // Limpa seleção anterior ao mudar fornecedor
      setState(() {
        _selectedInstrumental = null;
        _instrumentaisDisponiveis = []; // Limpa lista antiga
      });
       widget.onInstrumentalSelecionado(null); // Notifica o pai

      if (widget.fornecedorUid != null) {
        _buscarInstrumentais(widget.fornecedorUid!);
      } else {
         // Se o fornecedor for deselecionado (nulo), limpa tudo
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    }
  }

  Future<void> _buscarInstrumentais(String fornecedorUid) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _instrumentaisDisponiveis = []; // Limpa antes de buscar
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('instrumentais')
          .where('fornecedorUid', isEqualTo: fornecedorUid)
          .get();

      List<Instrumentais> instrumentaisTemp = querySnapshot.docs
          .map((doc) => Instrumentais.fromFirestore(doc))
          .toList();

      setState(() {
        _instrumentaisDisponiveis = instrumentaisTemp;
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao buscar instrumentais: $e");
      setState(() {
        _error = "Erro ao carregar instrumentais: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostra nada se nenhum fornecedor estiver selecionado
    if (widget.fornecedorUid == null) {
      return SizedBox.shrink(); // Retorna um widget vazio
    }

    // Mostra indicador de carregamento
    if (_isLoading) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    // Mostra mensagem de erro
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, style: TextStyle(color: Colors.red)),
      ));
    }

    // Mostra mensagem se não houver instrumentais (estilo do usuário)
    if (_instrumentaisDisponiveis.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.orange,
              ),
              SizedBox(height: 8),
              Text(
                'Nenhum instrumental disponível para este fornecedor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra a lista de instrumentais usando RadioListTile (estilo do usuário)
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione um Instrumental',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Gera a lista de RadioListTile dinamicamente
            ...List.generate(_instrumentaisDisponiveis.length, (index) {
              final instrumental = _instrumentaisDisponiveis[index];
              return RadioListTile<Instrumentais>(
                title: Text(instrumental.nome),
                subtitle: Text(
                  // Formata o valor como moeda e exibe a contagem
                  'Valor: R\$ ${instrumental.valor.toStringAsFixed(2)} - Disponível: ${instrumental.contagem}',
                ),
                value: instrumental, // O valor único para este RadioButton
                groupValue: _selectedInstrumental, // O instrumental atualmente selecionado no grupo
                activeColor: const Color.fromARGB(255, 33, 46, 56), // Cor quando selecionado
                onChanged: (Instrumentais? value) {
                  setState(() {
                    _selectedInstrumental = value;
                  });
                  widget.onInstrumentalSelecionado(value); // Notifica o widget pai sobre a seleção
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
