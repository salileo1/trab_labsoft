import 'package:flutter/material.dart';

class CadastroCustomContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Color(0xFFF2E8C7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SizedBox(
                width: 250,
                height: 500,
                child: Image.network(
                  'https://media.istockphoto.com/id/175224365/pt/foto/instrumentos-cir%C3%BArgicos.jpg?s=170667a&w=0&k=20&c=A2eHpYDuYSxb46mChd_G5cJNCaj6VHQ1l4xpFWdBg0k=',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerRight,
                ),
              ),
      ),
    ));
  }
}





