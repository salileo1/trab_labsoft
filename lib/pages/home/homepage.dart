import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trab_labsoft/components/instrumentais/instrumental_add_modal.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';
import 'package:trab_labsoft/pages/adesao/fornecedor_adesao_form.dart';
import 'package:trab_labsoft/pages/auth/check_page.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_list_view_enhanced.dart';
import 'package:trab_labsoft/pages/solicitacao/historico_page.dart';
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

  // Define theme colors for consistency
  final Color primaryColor = const Color(0xFFF2E8C7); // Light background
  final Color primaryDarkColor = const Color(0xFF212E38); // Dark elements/AppBar/Drawer
  final Color accentColor = Colors.teal; // Example accent color for buttons

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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: primaryDarkColor, // Drawer background color
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryDarkColor), // Match drawer background
              child: Text(
                'Menu Principal',
                style: TextStyle(
                  color: primaryColor, // Light text on dark background
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Add drawer items based on user type
            ..._buildDrawerItems(context, tipoStr),
            // Logout Button at the bottom
            const Divider(color: Colors.white30),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              text: 'Logout',
              color: Colors.redAccent, // Highlight logout
              onTap: () async {
                Navigator.pop(context); // Close drawer first
                _confirmAndLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, String? tipoStr) {
    List<Widget> items = [];
    final instrumentaisListProvider = Provider.of<InstrumentaisList>(context, listen: false);

    // Common Items
    items.add(_buildDrawerItem(context, icon: Icons.list_alt, text: 'Ver Instrumentais', onTap: () {
      Navigator.pop(context);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => InstrumentaisListViewEnhanced(tipoStr: tipoStr),
      ));
    }));
    items.add(_buildDrawerItem(context, icon: Icons.history, text: 'Histórico Solicitações', onTap: () {
       Navigator.pop(context);
       Navigator.of(context).push(MaterialPageRoute(
         builder: (context) => const HistoricoSolicitacoesPage(),
       ));
    }));

    // Fornecedor Specific Items
    if (tipoStr == 'Fornecedor') {
      items.add(_buildDrawerItem(context, icon: Icons.add_circle_outline, text: 'Cadastrar Instrumental', onTap: () {
        Navigator.pop(context);
        _showCadInstrumentalModal(context, instrumentaisListProvider);
      }));
      items.add(_buildDrawerItem(context, icon: Icons.group_add_outlined, text: 'Aderir a Hospital', onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const FornecedorAdesaoForm(),
        ));
      }));
      items.add(_buildDrawerItem(context, icon: Icons.receipt_long_outlined, text: 'Solicitações Recebidas', onTap: () {
        Navigator.pop(context);
        // TODO: Navigate to Fornecedor's received requests page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade Pendente: Ver Solicitações Recebidas')),
        );
      }));
    }

    // Hospital Specific Items
    if (tipoStr == 'Hospital') {
      items.add(_buildDrawerItem(context, icon: Icons.add_shopping_cart, text: 'Solicitar Instrumental', onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const HospitalSolicitacaoInstrumentalForm(),
        ));
      }));
      items.add(_buildDrawerItem(context, icon: Icons.person_add_alt_1_outlined, text: 'Pedidos de Adesão', onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade Pendente: Ver Pedidos de Adesão')),
        );
      }));
    }

    return items;
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
    final itemColor = color ?? primaryColor; // Default to light color for text/icon
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(text, style: TextStyle(color: itemColor, fontSize: 16)),
      onTap: onTap,
    );
  }

  // --- Body Content Implementation ---

  // Build action buttons similar to reference, using ElevatedButton
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String text, required VoidCallback onPressed, Color? buttonColor}) {
    final color = buttonColor ?? accentColor; // Use accent color or provided color
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(text, textAlign: TextAlign.center),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color, // Text color, Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Less rounded than StadiumBorder
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        minimumSize: const Size(140, 45), // Ensure minimum button size
      ),
    );
  }

  // Get list of action buttons for the body
  List<Widget> _getBodyActionButtons(BuildContext context, String? tipoStr) {
    List<Widget> buttons = [];
    final instrumentaisListProvider = Provider.of<InstrumentaisList>(context, listen: false);

    // Common
    buttons.add(_buildActionButton(context, icon: Icons.list_alt, text: 'Ver Instrumentais', onPressed: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => InstrumentaisListViewEnhanced(tipoStr: tipoStr),
      ));
    }, buttonColor: Colors.blueGrey[700]));
    buttons.add(_buildActionButton(context, icon: Icons.history, text: 'Histórico', onPressed: () {
       Navigator.of(context).push(MaterialPageRoute(
         builder: (context) => const HistoricoSolicitacoesPage(),
       ));
    }, buttonColor: Colors.blueGrey[600]));

    // Fornecedor
    if (tipoStr == 'Fornecedor') {
      buttons.add(_buildActionButton(context, icon: Icons.add_circle_outline, text: 'Cadastrar Item', onPressed: () {
        _showCadInstrumentalModal(context, instrumentaisListProvider);
      }, buttonColor: Colors.green[700]));
      buttons.add(_buildActionButton(context, icon: Icons.group_add_outlined, text: 'Aderir Hospital', onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const FornecedorAdesaoForm(),
        ));
      }, buttonColor: Colors.orange[800]));
      buttons.add(_buildActionButton(context, icon: Icons.receipt_long_outlined, text: 'Solicitações', onPressed: () {
        // TODO: Navigate to Fornecedor's received requests page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade Pendente: Ver Solicitações Recebidas')),
        );
      }, buttonColor: Colors.purple[700]));
    }

    // Hospital
    if (tipoStr == 'Hospital') {
      buttons.add(_buildActionButton(context, icon: Icons.add_shopping_cart, text: 'Solicitar Item', onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const HospitalSolicitacaoInstrumentalForm(),
        ));
      }, buttonColor: Colors.cyan[700]));
      buttons.add(_buildActionButton(context, icon: Icons.person_add_alt_1_outlined, text: 'Adesões', onPressed: () {
        // TODO: Navigate to Hospital's adhesion requests page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade Pendente: Ver Pedidos de Adesão')),
        );
      }, buttonColor: Colors.red[600]));
    }

    return buttons;
  }

  // --- Helper Methods ---

  void _showCadInstrumentalModal(BuildContext context, InstrumentaisList provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CadInstrumentalForm(
          onSubmit: (formData) async {
            try {
              await provider.cadastrarInstrumentais(formData.nome, formData.valor, context);
              if (!context.mounted) return;
              Navigator.pop(context); // Close modal on success
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Instrumental criado com sucesso!'), backgroundColor: Colors.green),
              );
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao criar instrumental: $error'), backgroundColor: Colors.red),
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
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final actionButtons = _getBodyActionButtons(context, tipoStr);

    return Scaffold(
      backgroundColor: primaryColor, // Light background for the body
      appBar: AppBar(
        title: Text('Olá, ${nomeUsuario ?? 'Usuário'}'),
        backgroundColor: primaryDarkColor,
        foregroundColor: primaryColor, // Color for title and drawer icon
        elevation: 2.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _confirmAndLogout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context), // Add the drawer
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Message (similar to reference)
              Text(
                'Bem-vindo(a)!',
                style: TextStyle(
                  fontSize: 32, // Larger font
                  fontWeight: FontWeight.bold,
                  color: primaryDarkColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione uma das opções abaixo para continuar.', // Informative subtitle
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryDarkColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons using Wrap (similar to reference)
              if (tipoStr == null)
                const CircularProgressIndicator()
              else if (actionButtons.isEmpty)
                const Text("Nenhuma ação disponível.")
              else
                Wrap(
                  spacing: 16, // Horizontal space between buttons
                  runSpacing: 16, // Vertical space between button rows
                  alignment: WrapAlignment.center, // Center buttons horizontally
                  children: actionButtons,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

