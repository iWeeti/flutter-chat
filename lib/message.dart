import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rfid_sovellus/user.dart';
import 'dart:developer' as developer;

class WSMessage {
  int id;
  String content;
  WSUser author;

  WSMessage(this.id, this.content, this.author);

  static Future<WSMessage> fromJsonString(String json) async {
    developer.log(json, name: "websocket");
    dynamic d = jsonDecode(json);
    WSUser? user = await WSUser.getUser(d['author_id']);
    if (user == null) throw Exception("Message has no author");
    return WSMessage(d['id'], d['content'], user);
  }

  static Future<WSMessage> fromJson(Map json) async {
    developer.log("bruh: ${json['id']}", name: "websocket");
    WSUser? user = await WSUser.getUser(json['author_id']);
    if (user == null) throw Exception("Message has no author");
    return WSMessage(json['id'], json['content'], user);
  }
}

class Message extends StatefulWidget {
  final String user;
  final String message;

  const Message(this.user, this.message, {Key? key}) : super(key: key);

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  @override
  Widget build(BuildContext context) {
    return Card(
        child: (ListTile(
      leading: const Icon(Icons.person),
      title: Text(widget.message),
    )));
  }
}
