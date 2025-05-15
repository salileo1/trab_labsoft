// Enum para o tipo de usuário
enum TipoUsuario {
  hospital,
  fornecedor,
}

// Função auxiliar para converter String para TipoUsuario e vice-versa
String tipoUsuarioToString(TipoUsuario tipo) {
  return tipo.toString().split('.').last;
}

TipoUsuario stringToTipoUsuario(String tipoStr) {
  return TipoUsuario.values.firstWhere(
    (e) => e.toString().split('.').last == tipoStr,
    orElse: () => TipoUsuario.hospital, // Valor padrão ou tratar erro
  );
}

class Usuario {
  String id;
  String nome;
  String email;
  TipoUsuario tipoUsuario;
  String? telefone;
  String? cnpj; 
  String? endereco;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
    this.cnpj,
    this.endereco,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipoUsuario': tipoUsuarioToString(tipoUsuario),
      'telefone': telefone,
      'cnpj': cnpj,
      'endereco': endereco,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      tipoUsuario: stringToTipoUsuario(json['tipoUsuario'] ?? 'hospital'),
      telefone: json['telefone'],
      cnpj: json['cnpj'],
      endereco: json['endereco'],
    );
  }
}

