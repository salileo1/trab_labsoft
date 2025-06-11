import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trab_labsoft/components/solciitacoes/dropdown_fornecedores.dart'; // Assuming this returns a Fornecedor object with uid and nome
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';

class HospitalSolicitacaoInstrumentalForm extends StatefulWidget {
  const HospitalSolicitacaoInstrumentalForm({Key? key}) : super(key: key);

  @override
  _HospitalSolicitacaoInstrumentalFormState createState() =>
      _HospitalSolicitacaoInstrumentalFormState();
}

class _HospitalSolicitacaoInstrumentalFormState
    extends State<HospitalSolicitacaoInstrumentalForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingFornecedores = true; // Added for clarity
  bool _isLoadingInstrumentais = false; // Renamed for clarity
  bool _isSendingRequest = false;
  // Assuming DropdownFornecedores returns FornecedorData or similar object
  Fornecedor? _selectedFornecedorData;
  List<Instrumentais> _instrumentaisDisponiveis = [];
  Instrumentais? _selectedInstrumental;
  final _quantidadeController = TextEditingController(text: '1');
  final _observacoesController = TextEditingController();
  final _dataEntregaController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initial loading state can be handled within DropdownFornecedores or here
    // For simplicity, assume DropdownFornecedores handles its own loading indicator
    _isLoadingFornecedores = false; // Assuming dropdown handles its loading
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacoesController.dispose();
    _dataEntregaController.dispose();
    super.dispose();
  }

  Future<void> _carregarInstrumentaisDoFornecedor(String fornecedorUid) async {
    setState(() {
      _isLoadingInstrumentais = true;
      _instrumentaisDisponiveis = []; // Clear previous list
      _selectedInstrumental = null; // Reset selected instrumental
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(fornecedorUid)
          .collection('instrumentais')
          .get();

      final instrumentais = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure correct parsing, especially for numeric types
        final valor = (data['valor'] is String)
            ? (double.tryParse(data['valor']) ?? 0.0)
            : (data['valor']?.toDouble() ?? 0.0);
        final contagem = (data['contagem'] is String)
            ? (int.tryParse(data['contagem']) ?? 0)
            : (data['contagem']?.toInt() ?? 0);

        return Instrumentais(
          id: doc.id, // Use doc.id as the instrumental ID
          nome: data['nome'] ?? 'Nome Indisponível',
          valor: valor,
          contagem: contagem,
        );
      }).toList();

      // Filter out instrumentals with count 0 if needed
      // instrumentais.removeWhere((inst) => inst.contagem <= 0);


      setState(() {
        _instrumentaisDisponiveis = instrumentais;
        _isLoadingInstrumentais = false;
      });
    } catch (e) {
      print('Erro ao buscar instrumentais do fornecedor $fornecedorUid: $e');
      setState(() {
        _isLoadingInstrumentais = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar instrumentais: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _selecionarData() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 33, 46, 56),
              onPrimary: Color(0xFFF2E8C7),
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dataEntregaController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      });
    }
  }

  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInstrumental == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um instrumental')),
      );
      return;
    }
     if (_selectedFornecedorData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um fornecedor')),
      );
      return;
    }


    setState(() {
      _isSendingRequest = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final quantidade = int.parse(_quantidadeController.text);
      final valorUnitario = _selectedInstrumental!.valor;
      final valorTotal = valorUnitario * quantidade;


      final solicitacaoData = {
        'hospitalId': userId,
        'fornecedorId': _selectedFornecedorData!.uid, 
        'fornecedorNome': _selectedFornecedorData!.nome, 
        'instrumentalId': _selectedInstrumental!.id,
        'instrumentalNome': _selectedInstrumental!.nome,
        'quantidade': quantidade,
        'valorUnitario': valorUnitario,
        'valorTotal': valorTotal,
        'observacoes': _observacoesController.text,
        'dataEntregaDesejada': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null, // Use Timestamp
        'status': 'pendente',
        'dataSolicitacao': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('solicitacoesInstrumental')
          .add(solicitacaoData);

      // Decrement count in supplier's inventory (optional, depends on requirements)
      // Consider transactions for atomicity if decrementing count
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(_selectedFornecedorData!.uid)
      //     .collection('instrumentais')
      //     .doc(_selectedInstrumental!.id)
      //     .update({'contagem': FieldValue.increment(-quantidade)});


      setState(() {
        _isSendingRequest = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _quantidadeController.text = '1';
      _observacoesController.clear();
      _dataEntregaController.clear();
      setState(() {
        _selectedFornecedorData = null;
        _selectedInstrumental = null;
        _selectedDate = null;
        _instrumentaisDisponiveis = [];
      });

    } catch (e) {
      setState(() {
        _isSendingRequest = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar solicitação: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  int _calcularQuantidade() {
    return int.tryParse(_quantidadeController.text) ?? 0;
  }

  double _calcularValorTotal() {
    if (_selectedInstrumental == null) return 0.0;
    return _selectedInstrumental!.valor * _calcularQuantidade();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Instrumental'),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        elevation: 2,
      ),
      body: _isLoadingFornecedores
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            const Text(
                              'Selecione um Fornecedor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Ensure DropdownFornecedores calls onFornecedorSelecionado
                            // with a FornecedorData object (or null)
                            DropdownFornecedores(
                              onFornecedorSelecionado: (Fornecedor? fornecedor) { // Explicitly typed
                                setState(() {
                                   _selectedFornecedorData = fornecedor; // Assign directly
                                   // Clear dependent fields when supplier changes
                                   _instrumentaisDisponiveis = [];
                                   _selectedInstrumental = null;
                                });
                                if (fornecedor != null) {
                                  print('Fornecedor selecionado: ${fornecedor.nome} (UID: ${fornecedor.uid})');
                                  _carregarInstrumentaisDoFornecedor(fornecedor.uid);
                                } else {
                                  print('Nenhum fornecedor selecionado.');
                                  // No need to load instrumentals if none selected
                                   setState(() {
                                     _isLoadingInstrumentais = false; // Ensure loading stops
                                   });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Show loading indicator for instrumentals
                    if (_isLoadingInstrumentais)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 33, 46, 56),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Carregando instrumentais disponíveis...'),
                          ],
                        ),
                      ),

                    // Show message if no instrumentals are available AFTER loading
                    if (_selectedFornecedorData != null && !_isLoadingInstrumentais && _instrumentaisDisponiveis.isEmpty)
                      Card(
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
                      ),

                    // Show instrumentals list if available and not loading
                    if (_selectedFornecedorData != null && !_isLoadingInstrumentais && _instrumentaisDisponiveis.isNotEmpty)
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
                              const Text(
                                'Selecione um Instrumental',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Use ListView.builder for potentially long lists
                              ListView.builder(
                                shrinkWrap: true, // Important inside SingleChildScrollView
                                physics: NeverScrollableScrollPhysics(), // Disable scrolling within the list
                                itemCount: _instrumentaisDisponiveis.length,
                                itemBuilder: (context, index) {
                                  final instrumental = _instrumentaisDisponiveis[index];
                                  return RadioListTile<Instrumentais>(
                                    title: Text(instrumental.nome),
                                    subtitle: Text(
                                      'Valor: R\$ ${instrumental.valor.toStringAsFixed(2)} - Disponível: ${instrumental.contagem}',
                                    ),
                                    value: instrumental,
                                    groupValue: _selectedInstrumental,
                                    activeColor: const Color.fromARGB(255, 33, 46, 56),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedInstrumental = value;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Show details section only if an instrumental is selected
                    if (_selectedInstrumental != null)
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
                              const Text(
                                'Detalhes da Solicitação',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _quantidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade',
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 33, 46, 56),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  // Force update of total value display if needed elsewhere
                                  setState(() {});
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a quantidade';
                                  }
                                  final quantidade = int.tryParse(value);
                                  if (quantidade == null || quantidade <= 0) {
                                    return 'Quantidade inválida';
                                  }
                                  // Check against available count
                                  if (_selectedInstrumental != null && quantidade > _selectedInstrumental!.contagem) {
                                    return 'Quantidade maior que a disponível (${_selectedInstrumental!.contagem})';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _dataEntregaController,
                                decoration: InputDecoration(
                                  labelText: 'Data de Entrega Desejada',
                                  border: const OutlineInputBorder(),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 33, 46, 56),
                                      width: 2.0,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: _selecionarData,
                                  ),
                                ),
                                readOnly: true,
                                onTap: _selecionarData,
                                validator: (value) {
                                  // Make date optional or required based on needs
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Selecione a data de entrega';
                                  // }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _observacoesController,
                                decoration: const InputDecoration(
                                  labelText: 'Observações (Opcional)',
                                  border: OutlineInputBorder(),
                                   focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 33, 46, 56),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24),
                              // Display summary
                              Text(
                                'Resumo:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text('Instrumental: ${_selectedInstrumental?.nome ?? '-'}'),
                              Text('Quantidade: ${_calcularQuantidade()}'),
                              Text('Valor Unitário: R\$ ${_selectedInstrumental?.valor.toStringAsFixed(2) ?? '0.00'}'),
                              Text(
                                'Valor Total: R\$ ${_calcularValorTotal().toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              // Submit Button
                              Center(
                                child: _isSendingRequest
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: _enviarSolicitacao,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 50, vertical: 15),
                                          textStyle: const TextStyle(fontSize: 16),
                                        ),
                                        child: const Text('Enviar Solicitação', style: TextStyle(color: Colors.white),),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Placeholder for FornecedorData - replace with your actual model
class FornecedorData {
  final String uid;
  final String nome;

  FornecedorData({required this.uid, required this.nome});
}

// Placeholder for Instrumentais model - ensure it matches your actual model
// class Instrumentais {
//   final String id;
//   final String nome;
//   final double valor;
//   final int contagem;

//   Instrumentais({
//     required this.id,
//     required this.nome,
//     required this.valor,
//     required this.contagem,
//   });
// }

