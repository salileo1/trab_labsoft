import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/models/users/usuario_model.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_page.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_add_modal.dart';
import 'package:provider/provider.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_list_view_enhanced.dart';
import 'package:trab_labsoft/pages/adesao/fornecedor_adesao_form.dart';
import 'package:trab_labsoft/pages/solicitacao/hospital_solicitacao_instrumental_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? usuarioId;
  String? nomeUsuario;
  String? tipoStr;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usuarioId = prefs.getString('usuarioId');
      nomeUsuario = prefs.getString('usuarioNome');
      tipoStr = prefs.getString('tipoUsuario');
    });
  }

  @override
  Widget build(BuildContext context) {
    final instrumentaisList = Provider.of<InstrumentaisList>(context);
    final meusInstrumentais = instrumentaisList.items.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: const Color(0xFF212E38),
        iconTheme: const IconThemeData(color: Color(0xFFF2E8C7)),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xFF212E38),
                    ),
                    child: Text(
                      'Olá, ${nomeUsuario ?? 'Usuário'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('Ver Instrumentais'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => InstrumentaisListViewEnhanced(tipoStr: tipoStr),
                      ));
                    },
                  ),
                  if (tipoStr == 'Fornecedor')
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Cadastrar Instrumental'),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return CadInstrumentalForm(
                            onSubmit: (formData) async {
                              try {
                                await Provider.of<InstrumentaisList>(context, listen: false)
                                    .cadastrarInstrumentais(formData.nome, formData.valor, context);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Instrumental criado com sucesso!')),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao criar instrumental: $error')),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (tipoStr == 'Fornecedor')
                    ListTile(
                      leading: const Icon(Icons.handshake),
                      title: const Text('Solicitar Adesão a um hospital'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const FornecedorAdesaoForm(),
                        ));
                      },
                    ),
                  if (tipoStr == 'Hospital')
                  ListTile(
                    leading: const Icon(Icons.medical_services),
                    title: const Text('Solicitar Instrumental'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const HospitalSolicitacaoInstrumentalForm(),
                      ));
                    },
                  ),
                  if (tipoStr == 'Hospital')
                   ListTile(
                      leading: const Icon(Icons.handshake),
                      title: const Text('Solicitações de Adesão'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const FornecedorAdesaoForm(),
                        ));
                      },
                    ),
                  if (tipoStr == 'Fornecedor')
                   ListTile(
                      leading: const Icon(Icons.handshake),
                      title: const Text('Solicitações de Instrumental'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const FornecedorAdesaoForm(),
                        ));
                      },
                    ),
                ],
              ),
            ),
            SafeArea(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const checkPage()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bem-vindo, ${nomeUsuario ?? 'Usuário'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Você possui ${meusInstrumentais.length} instrumental(is) cadastrados.',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
