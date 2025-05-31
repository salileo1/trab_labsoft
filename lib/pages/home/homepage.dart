import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_add_modal.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/adesao/fornecedor_adesao_form.dart';
import 'package:trab_labsoft/pages/adesao/lista_fornecedores_page.dart';
import 'package:trab_labsoft/pages/adesao/lista_solicitacoes_adesao_page.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_list_view_enhanced.dart';
import 'package:trab_labsoft/pages/solicitacao/historico_page.dart';
import 'package:trab_labsoft/pages/solicitacao/hospital_solicitacao_instrumental_form.dart';
import 'package:trab_labsoft/pages/solicitacao/solicitacoes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? usuarioId;
  String? nomeUsuario;
  String? tipoStr;

  // Cor base para botões
  final Color buttonGreen = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        usuarioId = prefs.getString('usuarioId');
        nomeUsuario = prefs.getString('usuarioNome');
        tipoStr = prefs.getString('tipoUsuario');
      });
    }
  }

  /// Conteúdo “puro” da drawer, sem o widget Drawer em si.
  Widget _buildDrawerContent(BuildContext context) {
    return Container(
      color: buttonGreen, // Fundo verde
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: buttonGreen),
            child: Text(
              'Menu Principal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Itens comuns
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            text: 'Ver Instrumentais',
            onTap: () {
              // Se for layout grande, não fecha nada; senão, fecha drawer normalmente:
              if (MediaQuery.of(context).size.width < 600) {
                Navigator.pop(context);
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) =>
                      InstrumentaisListViewEnhanced(tipoStr: tipoStr),
                ),
              );
            },
            color: Colors.white,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            text: 'Histórico Solicitações',
            onTap: () {
              if (MediaQuery.of(context).size.width < 600) {
                Navigator.pop(context);
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const HistoricoSolicitacoesPage(),
                ),
              );
            },
            color: Colors.white,
          ),
          // Itens para Fornecedor
          if (tipoStr == 'Fornecedor') ...[
            _buildDrawerItem(
              context,
              icon: Icons.add_circle_outline,
              text: 'Cadastrar Instrumental',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                final instrumentaisListProvider =
                    Provider.of<InstrumentaisList>(context, listen: false);
                _showCadInstrumentalModal(context, instrumentaisListProvider);
              },
              color: Colors.white,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.group_add_outlined,
              text: 'Solicitar Adesão Hospital',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const SolicitacaoAdesaoPage(),
                  ),
                );
              },
              color: Colors.white,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.pending_actions,
              text: 'Solicitações Pendentes',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const SolicitacoesPendentesPage(),
                  ),
                );
              },
              color: Colors.white,
            ),
          ],
          // Itens para Hospital
          if (tipoStr == 'Hospital') ...[
            _buildDrawerItem(
              context,
              icon: Icons.add_shopping_cart,
              text: 'Solicitar Instrumental',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const HospitalSolicitacaoInstrumentalForm(),
                  ),
                );
              },
              color: Colors.white,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.manage_accounts,
              text: 'Gerenciar Adesões',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ListaSolicitacoesAdesaoPage(),
                  ),
                );
              },
              color: Colors.white,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.manage_accounts,
              text: 'Lista de Fornecedores',
              onTap: () {
                if (MediaQuery.of(context).size.width < 600) {
                  Navigator.pop(context);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ListaFornecedoresPage(),
                  ),
                );
              },
              color: Colors.white,
            ),
          ],
          const Divider(color: Colors.white30),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Logout',
            onTap: () {
              if (MediaQuery.of(context).size.width < 600) {
                Navigator.pop(context);
              }
              _confirmAndLogout(context);
            },
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  /// Método que usa o conteúdo da drawer dentro de um widget Drawer (para telas pequenas).
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(text, style: TextStyle(color: itemColor, fontSize: 16)),
      onTap: onTap,
    );
  }

  /// Botão verde uniforme, tamanho fixo (180×60).
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(text, textAlign: TextAlign.center),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: buttonGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        minimumSize: const Size(180, 60), // Largura e altura iguais
      ),
    );
  }

  List<Widget> _getBodyActionButtons(BuildContext context, String? tipoStr) {
    List<Widget> buttons = [];
    final instrumentaisListProvider =
        Provider.of<InstrumentaisList>(context, listen: false);

    // Botões comuns
    buttons.add(
      _buildActionButton(
        context,
        icon: Icons.list_alt,
        text: 'Ver Instrumentais',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) =>
                  InstrumentaisListViewEnhanced(tipoStr: tipoStr),
            ),
          );
        },
      ),
    );
    buttons.add(
      _buildActionButton(
        context,
        icon: Icons.history,
        text: 'Histórico',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const HistoricoSolicitacoesPage(),
            ),
          );
        },
      ),
    );

    // Para Fornecedor
    if (tipoStr == 'Fornecedor') {
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.add_circle_outline,
          text: 'Cadastrar Item',
          onPressed: () {
            _showCadInstrumentalModal(context, instrumentaisListProvider);
          },
        ),
      );
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.group_add_outlined,
          text: 'Solicitar Adesão',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const SolicitacaoAdesaoPage(),
              ),
            );
          },
        ),
      );
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.pending_actions,
          text: 'Solicitações Pendentes',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const SolicitacoesPendentesPage(),
              ),
            );
          },
        ),
      );
    }

    // Para Hospital
    if (tipoStr == 'Hospital') {
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.add_shopping_cart,
          text: 'Solicitar Item',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const HospitalSolicitacaoInstrumentalForm(),
              ),
            );
          },
        ),
      );
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.manage_accounts,
          text: 'Gerenciar Adesões',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const ListaSolicitacoesAdesaoPage(),
              ),
            );
          },
        ),
      );
      buttons.add(
        _buildActionButton(
          context,
          icon: Icons.manage_accounts,
          text: 'Lista de Fornecedores',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const ListaFornecedoresPage(),
              ),
            );
          },
        ),
      );
    }

    return buttons;
  }

  void _showCadInstrumentalModal(
      BuildContext context, InstrumentaisList provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CadInstrumentalForm(
          onSubmit: (formData) async {
            try {
              await provider.cadastrarInstrumentais(
                  formData.nome, formData.valor, formData.contagem, context);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instrumental criado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao criar instrumental: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const checkPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Largura da tela
    final screenWidth = MediaQuery.of(context).size.width;
    // Botões para o corpo
    final actionButtons = _getBodyActionButtons(context, tipoStr);

    // Conteúdo principal (corpo) que exibimos no Scaffold
    Widget mainContent = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo(a)!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: buttonGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione uma das opções abaixo para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: buttonGreen.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            if (tipoStr == null)
              const CircularProgressIndicator()
            else if (actionButtons.isEmpty)
              const Text("Nenhuma ação disponível.")
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: actionButtons,
              ),
          ],
        ),
      ),
    );

    // AppBar (idêntica em ambas as versões)
    AppBar appBar = AppBar(
      title: Text(
        'Olá, ${nomeUsuario ?? 'Usuário'}',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: buttonGreen, // AppBar verde
      elevation: 2.0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          tooltip: 'Logout',
          onPressed: () => _confirmAndLogout(context),
        ),
      ],
    );

    // Se a largura for >= 600, mostra menu fixo à esquerda
    if (screenWidth >= 600) {
      return Scaffold(
        backgroundColor: Colors.white, // Fundo branco
        appBar: appBar,
        body: Row(
          children: [
            // Largura fixa de 250px para o menu
            SizedBox(
              width: 250,
              child: _buildDrawerContent(context),
            ),
            const VerticalDivider(
              width: 1,
              color: Colors.grey,
            ),
            // Conteúdo principal ocupa o restante
            Expanded(child: mainContent),
          ],
        ),
      );
    }

    // Para telas < 600, mantém drawer padrão
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      drawer: _buildDrawer(context),
      body: mainContent,
    );
  }
}
