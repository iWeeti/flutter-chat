import 'package:flutter/material.dart';
import 'package:rfid_sovellus/chat.dart';
import 'package:rfid_sovellus/contact.dart';

class ContactSelect extends StatefulWidget {
  const ContactSelect({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactSelectState();
}

class _ContactSelectState extends State<ContactSelect> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (() => Navigator.pop(context)),
        ),
        title: Text("Contact Select"),
      ),
      body: ListView(
        children: List.generate(
            5,
            (index) => Contact(
                  index,
                  (id) {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Chat(1)));
                  },
                )),
      ),
    );
  }
}
