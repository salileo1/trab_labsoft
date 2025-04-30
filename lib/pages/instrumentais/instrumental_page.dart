import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:trab_labsoft/pages/instrumentais/instrumental_list_view.dart';




class InstrumentaisPage extends StatefulWidget {
  const InstrumentaisPage({super.key});

  @override
  State<InstrumentaisPage> createState() => _InstrumentaisPageState();
}

class _InstrumentaisPageState extends State<InstrumentaisPage> {
  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color.fromARGB(255, 33, 46, 56),iconTheme: IconThemeData(color: Color(0xFFF2E8C7))),
      backgroundColor: const Color.fromARGB(255, 33, 46, 56),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
          
            children: [
              Expanded(
                child: InstrumentaisListViewPage(),
              ),
            ],
          );
        },
      ),
      );
  }
}