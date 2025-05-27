class Instrumentais {
  String id;
  String nome;
  double valor;
  int contagem;

  Instrumentais({
    required this.id,
    required this.nome,
    required this.valor,
    required this.contagem,
  });

  // Método para converter o objeto para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'contagem': contagem,
    };
  }

  // Método para criar uma instância a partir de JSON (opcional, útil para Firestore)
  factory Instrumentais.fromJson(Map<String, dynamic> json) {
    return Instrumentais(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      valor: (json['valor'] as num).toDouble(),
      contagem: json['contagem'] ?? 0,
    );
  }
}

class InstrumentaisFormData {
  String id;
  String nome;
  double valor;
  int contagem;

  InstrumentaisFormData({
    this.id = '',
    this.nome = '',
    this.valor = 0.0,
    this.contagem = 0,
  });
}