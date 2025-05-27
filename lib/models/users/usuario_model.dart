import 'package:cloud_firestore/cloud_firestore.dart';

// Enum para o tipo de usuário
enum TipoUsuario {
  hospital,
  fornecedor,
}

// Funções auxiliares de conversão
String tipoUsuarioToString(TipoUsuario tipo) {
  return tipo.name;
}

TipoUsuario stringToTipoUsuario(String tipoStr) {
  return TipoUsuario.values.firstWhere(
    (e) => e.name == tipoStr,
    orElse: () => TipoUsuario.hospital,
  );
}

// Modelo do usuário
class Usuario {
  final String id;
  final String nome;
  final String email;
  final TipoUsuario tipoUsuario;
  final String? telefone;
  final String? cnpj;
  final String? endereco;
  final String? genero;
  final DateTime? dataNascimento;
  final Timestamp? createdAt;
  final List? fornecedores;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
    this.cnpj,
    this.endereco,
    this.genero,
    this.dataNascimento,
    this.fornecedores,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'nome': nome,
      'email': email,
      'tipoUsuario': tipoUsuarioToString(tipoUsuario),
      'telefone': telefone,
      'cnpj': cnpj,
      'endereco': endereco,
      'genero': genero,
      'dataNascimento': dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
      'fornecedores': fornecedores,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['uid'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      tipoUsuario: stringToTipoUsuario(json['tipoUsuario'] ?? 'hospital'),
      telefone: json['telefone'],
      cnpj: json['cnpj'],
      endereco: json['endereco'],
      genero: json['genero'],
      dataNascimento: (json['dataNascimento'] is Timestamp)
          ? (json['dataNascimento'] as Timestamp).toDate()
          : null,
      fornecedores: json['fornecedores'],
      createdAt: json['createdAt'] is Timestamp ? json['createdAt'] : null,
    );
  }
}
