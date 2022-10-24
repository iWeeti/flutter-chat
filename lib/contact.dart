import 'package:flutter/material.dart';

class Contact extends StatelessWidget {
  final void Function(int) onPressed;
  int id;

  Contact(this.id, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text("John Doe"),
        onTap: () {
          onPressed(id);
        },
      ),
    );
  }
}
