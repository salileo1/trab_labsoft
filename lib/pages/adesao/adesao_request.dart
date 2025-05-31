import 'package:cloud_firestore/cloud_firestore.dart';

class AdesaoRequest {
  final String id; // Firestore document ID
  final String fornecedorId;
  final String fornecedorNome;
  final String hospitalId;
  // hospitalNome might be fetched separately or stored redundantly
  String? hospitalNome;
  String status; // 'pendente', 'aceita', 'rejeitada'
  final Timestamp requestTimestamp;

  AdesaoRequest({
    required this.id,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.hospitalId,
    this.hospitalNome,
    required this.status,
    required this.requestTimestamp,
  });

  factory AdesaoRequest.fromFirestore(DocumentSnapshot doc, {String? hospitalNome}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdesaoRequest(
      id: doc.id,
      fornecedorId: data['fornecedorId'] ?? '',
      fornecedorNome: data['fornecedorNome'] ?? 'Nome Indisponível',
      hospitalId: data['hospitalId'] ?? '',
      hospitalNome: hospitalNome, // Assign if fetched separately
      status: data['status']?.toLowerCase() ?? 'desconhecido',
      requestTimestamp: data['requestTimestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fornecedorId': fornecedorId,
      'fornecedorNome': fornecedorNome,
      'hospitalId': hospitalId,
      // Don't store hospitalNome here if it's fetched dynamically
      'status': status,
      'requestTimestamp': requestTimestamp,
    };
  }
}

