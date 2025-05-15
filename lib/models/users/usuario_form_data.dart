import "./usuario_model.dart";

class UsuarioFormData {
  String id;
  String nome;
  String email;
  String senha;
  String confirmarSenha;
  TipoUsuario tipoUsuario;
  String? telefone;
  String? cnpj;
  String? endereco;

  UsuarioFormData({
    this.id = '',
    this.nome =   '',
    this.email = '',
    this.senha = '',
    this.confirmarSenha = '',
    this.tipoUsuario = TipoUsuario.hospital, 
    this.telefone,
    this.cnpj,
    this.endereco,
  });
}

