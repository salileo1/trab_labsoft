import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo simples para representar um Fornecedor (Usuário)
class Fornecedor {
  final String uid;
  final String nome;

  Fornecedor({required this.uid, required this.nome});

  // Construtor factory para criar a partir de um DocumentSnapshot
  factory Fornecedor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Fornecedor(
      uid: doc.id,
      nome: data['nome'] ?? 'Nome não encontrado', // Use um valor padrão caso 'nome' não exista
    );
  }
}

class DropdownFornecedores extends StatefulWidget {
  final Function(Fornecedor?) onFornecedorSelecionado;

  const DropdownFornecedores({Key? key, required this.onFornecedorSelecionado}) : super(key: key);

  @override
  _DropdownFornecedoresState createState() => _DropdownFornecedoresState();
}

class _DropdownFornecedoresState extends State<DropdownFornecedores> {
  List<Fornecedor> _listaFornecedores = [];
  Fornecedor? _fornecedorSelecionado;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarFornecedoresDoUsuarioAtual();
  }

  Future<void> _buscarFornecedoresDoUsuarioAtual() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // 1. Obter o UID do usuário atual
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Usuário não autenticado.");
      }
      String currentUserUid = currentUser.uid;

      // 2. Buscar o documento do usuário atual
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      if (!userDoc.exists) {
        throw Exception("Documento do usuário atual não encontrado.");
      }

      // 3. Obter a lista de UIDs de fornecedores do campo 'fornecedores'
      List<String> fornecedoresUids = [];
      var userData = userDoc.data() as Map<String, dynamic>?; // Cast seguro
      if (userData != null && userData.containsKey('fornecedores') && userData['fornecedores'] is List) {
         // Garantir que os elementos da lista são strings
        fornecedoresUids = List<String>.from(userData['fornecedores'].map((item) => item.toString()));
      }

      if (fornecedoresUids.isEmpty) {
        // Se não houver fornecedores, termina o carregamento
        setState(() {
          _listaFornecedores = [];
          _carregando = false;
        });
        return;
      }

      // 4. Buscar os documentos de cada fornecedor (usuário)
      List<Fornecedor> fornecedoresTemp = [];
      for (String uid in fornecedoresUids) {
        try {
          DocumentSnapshot fornecedorDoc = await FirebaseFirestore.instance
              .collection('users') // Busca na mesma coleção 'users'
              .doc(uid)
              .get();

          if (fornecedorDoc.exists) {
            fornecedoresTemp.add(Fornecedor.fromFirestore(fornecedorDoc));
          } else {
            print("Aviso: Fornecedor com UID $uid não encontrado na coleção 'users'.");
            // Opcional: Adicionar um fornecedor 'fantasma' ou ignorar
            // fornecedoresTemp.add(Fornecedor(uid: uid, nome: 'Fornecedor não encontrado'));
          }
        } catch (e) {
          print("Erro ao buscar fornecedor com UID $uid: $e");
          // Tratar erro individual se necessário
        }
      }

      // 5. Atualizar o estado com a lista de fornecedores
      setState(() {
        _listaFornecedores = fornecedoresTemp;
        _carregando = false;
        // Opcional: Definir um valor inicial para o dropdown se a lista não estiver vazia
        // if (_listaFornecedores.isNotEmpty) {
        //   _fornecedorSelecionado = _listaFornecedores.first;
        //   widget.onFornecedorSelecionado(_fornecedorSelecionado);
        // }
      });

    } catch (e) {
      print("Erro ao buscar fornecedores: $e");
      setState(() {
        _erro = "Erro ao carregar fornecedores: ${e.toString()}";
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(child: Text(_erro!, style: TextStyle(color: Colors.red)));
    }

    if (_listaFornecedores.isEmpty) {
      return Center(child: Text("Nenhum fornecedor associado."));
    }

    // 6. Construir o DropdownButton
    return DropdownButtonFormField<Fornecedor>(
      value: _fornecedorSelecionado, // O fornecedor atualmente selecionado
      decoration: const InputDecoration(
                                labelText: 'Fornecedor',
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 33, 46, 56),
                                    width: 2.0,
                                  ),
                                ),
                              ),
      onChanged: (Fornecedor? novoValor) {
        setState(() {
          _fornecedorSelecionado = novoValor;
        });
        widget.onFornecedorSelecionado(novoValor); 
      },
      items: _listaFornecedores.map<DropdownMenuItem<Fornecedor>>((Fornecedor fornecedor) {
        return DropdownMenuItem<Fornecedor>(
          value: fornecedor, 
          child: Text(fornecedor.nome), 
        );
      }).toList(),
    );
  }
}
