import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';




class InstrumentaisList with ChangeNotifier {
  late final List<Instrumentais> _items;

  InstrumentaisList() {
    _items = [];
    _carregarServicos();
  }
  List<Instrumentais> get items => [..._items];


  List<Map<String, dynamic>> toJson() {
    return _items.map((instrumental) => instrumental.toJson()).toList();
  }

  factory InstrumentaisList.fromJson(List<Map<String, dynamic>> jsonList) {
    final intrumentalList = InstrumentaisList();
    intrumentalList._items.addAll(
      jsonList.map((json) => Instrumentais.fromJson(json)).toList(),
    );
    return intrumentalList;
  }

  Future<void> _carregarServicos() async {
    final List<Instrumentais> instrumentais = await buscarTodosInstrumentais(0);
    _items.addAll(instrumentais);
    notifyListeners();
  }

  Future<List<Instrumentais>> buscarTodosInstrumentais(int inicializacao) async {
    CollectionReference<Map<String, dynamic>> processosRef =
        FirebaseFirestore.instance.collection('instrumentais');

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await processosRef.get();

      List<Instrumentais> instrumentais = [];

      List<Future<void>> futures = querySnapshot.docs.map((doc) async {
        final resultado = doc.data();

        final negociacao = Instrumentais(
          id: resultado['id'].toString() ?? '',
          nome: resultado['nome'] ?? '',
          valor: resultado['valor'] ?? '',
          contagem: resultado['contagem'] ?? '',
        );

        instrumentais.add(negociacao);
      }).toList(); // Converter o iterável em uma lista

      // Aguardar todas as consultas aos fornecedores serem concluídas
      await Future.wait(futures);

      return instrumentais;
    } catch (e) {
      print('Erro ao buscar os instrumentais: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  Future<List<Map<String, dynamic>>> buscarInstrumentais() async {
    List<Map<String, dynamic>> instrumentais = [];

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('instrumentais').get();

      instrumentais = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return instrumentais;
    } catch (e) {
      print("Erro ao buscar instrumentais: $e");
      return [];
    }
  }

  Future<String> cadastrarInstrumentais(
    String id,
    String nome,
    double valor,
    BuildContext context,
  ) async {
    CollectionReference<Map<String, dynamic>> instrumentaisRef =
        FirebaseFirestore.instance.collection('instrumentais');

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await instrumentaisRef.get();

      List<int> ids = querySnapshot.docs.map((doc) {
        return int.parse(doc.id);
      }).toList();

      int ultimoId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
      int novoId = ultimoId + 1;


      final instrumentais = Instrumentais(
          id: novoId.toString(),
          nome: nome,
          valor: valor,
          contagem: 0,
         );

      await instrumentaisRef.doc(novoId.toString()).set({
        'id': novoId.toString(),
        'nome': nome,
        'valor': valor,
        'contagem': 0,
      });

     
      _items.add(instrumentais);
      notifyListeners();



      return instrumentais.id; // Retornar o ID do serviço cadastrado
    } catch (e) {
      print('Erro ao cadastrar o instrumental: $e');
      throw e; // Lançar a exceção para ser tratada no código que chama este método
    }
  }

  Future<void> removerInstrumental(String id) async {
    try {
      // Remover o procedimento da coleção no Firestore
      await FirebaseFirestore.instance.collection('instrumental').doc(id).delete();

      print('Instrumental removido do Firestore com sucesso');

      // Remover o procedimento da lista local
      _items.removeWhere((instrumental) => instrumental.id == id);

      print('Instrumental removido da lista local com sucesso');

      // Notificar os ouvintes sobre a mudança na lista
      notifyListeners();
    } catch (e) {
      print("Erro ao remover procedimento: $e");
    }
  }

  Future<Instrumentais?> buscarInstrumentalPorId(String idInstrumental) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('instrumentais')
              .where('id', isEqualTo: idInstrumental)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final instrumentalData = querySnapshot.docs[0].data();

        Instrumentais instrumentalRetornado = Instrumentais(
          id: instrumentalData['id'].toString() ?? '',
          nome: instrumentalData['nome'] ?? '',
          valor: instrumentalData['valor'] ?? '',
          contagem: instrumentalData['contagem'] ?? '',
        );

        return instrumentalRetornado;
      } else {
        return null; // Retorna null se não encontrar nenhum documento com o ID fornecido
      }
    } catch (e) {
      print("Erro ao buscar instrumental por ID: $e");
      return null;
    }
  }

  Future<void> atualizarInstrumental(
      String id, String novoNome, double novoValor) async {
    try {
      // Atualizar no Firestore
      await FirebaseFirestore.instance.collection('instrumentais').doc(id).update({
        'nome': novoNome,
        'valor': novoValor,
      });

      // Atualizar localmente
      int index = _items.indexWhere((intrumental) => intrumental.id == id);
      if (index != -1) {
        _items[index] = Instrumentais(
          id: id,
          nome: novoNome,
          valor: novoValor,
          contagem: _items[index].contagem,
        );
        notifyListeners();
      }
      print("instrumental atualizado com sucesso!");
    } catch (e) {
      print("Erro ao atualizar instrumental: $e");
    }
  }
}
