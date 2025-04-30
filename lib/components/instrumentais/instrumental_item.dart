import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais.dart';
import 'package:trab_labsoft/models/instrumentais/instrumentais_list.dart';


class instrumentalItem extends StatelessWidget {
  final Instrumentais instrumental;

  const instrumentalItem({required this.instrumental, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Consumer<InstrumentaisList>(
        builder: (context, instrumentalList, child) {
          return Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.topCenter,
                    child: IntrinsicHeight(
                      child: Text(
                        instrumental.nome,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.topCenter,
                    child: IntrinsicHeight(
                      child: Text(
                        'Valor: ${instrumental.valor.toStringAsFixed(2)}', // Garante que o valor seja exibido corretamente
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  // showDialog(
                  //   context: context,
                  //   builder: (context) => EditarProdutoDialog(
                  //     produto: produto,
                  //     onSalvar: (novoValor) { 
                  //       produtosList.atualizarServico(produto.id, produto.nome, novoValor);
                  //       Navigator.of(context).pop();
                  //     },
                  //   ),
                  // );
                },
              ),
              InkWell(
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onTap: () {
                  instrumentalList.removerInstrumental(instrumental.id);
                },
              )
            ],
          );
        },
      ),
    );
  }
}
