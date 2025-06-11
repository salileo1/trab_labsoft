import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<List<Instrumentais>> buscarTodosInstrumentais(
      int inicializacao) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final uid = user.uid;
    CollectionReference<Map<String, dynamic>> userRef = FirebaseFirestore
        .instance
        .collection('users')
        .doc(uid)
        .collection('instrumentais');

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await userRef.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Instrumentais(
          id: data['id'].toString(),
          nome: data['nome'] ?? '',
          valor: data['valor'] ?? '',
          contagem: data['contagem'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar os instrumentais do usuário: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> buscarInstrumentais() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('instrumentais')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Erro ao buscar instrumentais: $e");
      return [];
    }
  }

  Future<String> cadastrarInstrumentais(
    String nome,
    double valor,
    int contagem,
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado.");
    }

    final uid = user.uid;

    final userInstrumentaisRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('instrumentais');

    try {
      // Obter o último ID
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await userInstrumentaisRef.get();

      List<int> ids =
          querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
      int ultimoId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
      int novoId = ultimoId + 1;

      final instrumentais = Instrumentais(
        id: novoId.toString(),
        nome: nome,
        valor: valor,
        contagem: contagem,
      );

      final instrumentoData = {
        'id': novoId.toString(),
        'nome': nome,
        'valor': valor,
        'contagem': contagem,
      };


      await userInstrumentaisRef.doc(novoId.toString()).set(instrumentoData);

      // Atualizar estado local, se necessário
      _items.add(instrumentais);
      notifyListeners();

      return instrumentais.id;
    } catch (e) {
      print('Erro ao cadastrar o instrumental: $e');
      throw Exception('Erro ao cadastrar o instrumental: $e');
    }
  }

  Future<void> removerInstrumental(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Remover da coleção principal
      await FirebaseFirestore.instance
          .collection('instrumentais')
          .doc(id)
          .delete();

      // Remover da subcoleção do usuário
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('instrumentais')
          .doc(id)
          .delete();

      _items.removeWhere((instrumental) => instrumental.id == id);
      notifyListeners();
      print('Instrumental removido com sucesso');
    } catch (e) {
      print("Erro ao remover instrumental: $e");
    }
  }

  Future<Instrumentais?> buscarInstrumentalPorId(String idInstrumental) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('instrumentais')
              .doc(idInstrumental)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return Instrumentais(
          id: data['id'].toString(),
          nome: data['nome'] ?? '',
          valor: data['valor'] ?? '',
          contagem: data['contagem'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao buscar instrumental por ID: $e");
      return null;
    }
  }

  Future<void> atualizarInstrumental(
      String id, String novoNome, double novoValor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dadosAtualizados = {
        'nome': novoNome,
        'valor': novoValor,
      };

      // Atualizar na coleção principal
      await FirebaseFirestore.instance
          .collection('instrumentais')
          .doc(id)
          .update(dadosAtualizados);

      // Atualizar na subcoleção do usuário
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('instrumentais')
          .doc(id)
          .update(dadosAtualizados);

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

      print("Instrumental atualizado com sucesso!");
    } catch (e) {
      print("Erro ao atualizar instrumental: $e");
    }
  }
}
