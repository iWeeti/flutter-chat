import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:rfid_sovellus/message.dart';
import 'package:http/http.dart' as http;
import 'package:rfid_sovellus/user.dart';
import 'dart:developer' as developer;
import 'package:event_listener/event_listener.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shared_preferences/shared_preferences.dart';

class WSChat {
  static Map<int, WSChat> cache = {};
  // static Map<int, EventListener> listeners = {};

  static Future<WSChat?> getChat(int id) async {
    if (cache.containsKey(id)) {
      return cache[id];
    }

    final prefs = await SharedPreferences.getInstance();
    final response = await http
        .get(Uri.parse("http://weetisoft.xyz:9567/chat/$id"), headers: {
      HttpHeaders.authorizationHeader: prefs.getString("JWT") ?? ""
    });
    // if (response.statusCode == 200) {
    WSChat chat = await WSChat.fromJson(response.body);
    cache[id] = chat;
    return chat;
    // }
    // return null;
  }

  int id;
  List<WSUser> participants = [];
  List<WSMessage> messages = [];
  EventListener emitter = EventListener();
  // ChatState? state;

  WSChat(this.id) {
    emitter = EventListener();
  }

  void registerCallback(ChatState state) {
    emitter.on("messageCreate", state.newMessage);
  }

  void addParticipant(WSUser user) {
    participants.add(user);
  }

  static Future<WSChat> fromJson(String data) async {
    dynamic d = jsonDecode(data);

    WSChat chat = WSChat(d['id']);

    for (var userId in d['participants']) {
      WSUser? user = await WSUser.getUser(userId);
      if (user == null) continue;
      chat.addParticipant(user);
    }

    return chat;
  }

  Future<void> addMessageFromJson(Map data) async {
    WSMessage message = await WSMessage.fromJson(data);
    emitter.emit("messageCreate", message);
    messages.add(message);
  }
}

class Chat extends StatefulWidget {
  final int id;
  const Chat(this.id, {Key? key}) : super(key: key);

  @override
  State<Chat> createState() => ChatState(id);
}

class ChatState extends State<Chat> {
  bool firstBuild = true;
  bool scrolled = false;
  TextEditingController textEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  List<WSMessage> messages = [];
  final int id;
  bool shouldScroll = false;
  late String? chatName = "Loading...";
  final ItemScrollController _controller = ItemScrollController();

  ChatState(this.id);

  Future<void> fetchMessages() async {
    final response = await http
        .get(Uri.parse("http://weetisoft.xyz:9567/chat/$id/messages"));
    if (response.statusCode == 200) {
      developer.log(response.body, name: "bruh.exe");
      List<WSMessage> msgs = [];
      for (var d in jsonDecode(response.body)) {
        WSMessage? m = await WSMessage.fromJson(d);
        msgs.add(m);
      }
      setState(() {
        messages = msgs;
      });
      try {
        _controller.scrollTo(
            index: messages.length - 1,
            duration: const Duration(milliseconds: 0));
      } catch (exception) {
        developer.log(exception.toString());
      }
    } else {
      throw Exception("Couldn't load messages");
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    fetchMessages();
    WSChat.getChat(id).then((chat) {
      if (chat == null) return;
      chat.registerCallback(this);
    });
    getChatName();
  }

  Future<void> getChatName() async {
    final prefs = await SharedPreferences.getInstance();
    WSChat? chat = await WSChat.getChat(id);
    if (chat == null) {
      chatName = "Undefined";
      return;
    }
    String selfName = prefs.getString("username") ?? "";
    if (chat.participants.length > 2) {
      chatName = "Unnamed Group Chat";
      return;
    }
    for (var participant in chat.participants) {
      if (participant.username == selfName) continue;
      chatName = participant.username;
    }
  }

  void newMessage(message) {
    setState(() {
      messages.add(message);
      if (messages.isNotEmpty) {
        _controller.scrollTo(
            index: messages.length - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (() => Navigator.pop(context)),
          ),
          title: Text(chatName ?? "John Doe"),
        ),
        body: _body());
  }

  Future<void> sendMessage(content) async {
    developer.log(jsonEncode({"content": content}), name: "bruh.exe");
    final prefs = await SharedPreferences.getInstance();
    final response = await http.post(
        Uri.parse("http://weetisoft.xyz:9567/chat/$id/messages/create"),
        headers: {
          HttpHeaders.authorizationHeader: prefs.getString("JWT") ?? "",
          HttpHeaders.contentTypeHeader: "application/json"
        },
        body: jsonEncode({"content": content}));

    developer.log(response.body, name: "sent-message");
    if (response.statusCode == 200) {
      // var data = jsonDecode(response.body);
      // WSUser? user = await WSUser.getUser(data['author_id']);
      // if (user != null) {
      //   setState(() {
      // developer.log(user.username, name: "sent-message");
      // messages.add(Message(user.username, data["content"] ?? ""));
      // });
      // }
    } else {
      throw Exception("Couldn't load messages");
    }
  }

  Widget _body() {
    // messages.insert(
    //     0, const WSMessage("System", "This conversation is not encrypted."));

    var a = Stack(children: [
      Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: ScrollablePositionedList.builder(
          itemScrollController: _controller,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            WSMessage message = messages[index];
            return Message(message.author.username, message.content);
          },
        ),
      ),
      Positioned(
        bottom: 10,
        left: 10,
        right: 10,
        height: 60,
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          margin: const EdgeInsets.all(5),
          child: TextField(
            controller: textEditingController,
            focusNode: focusNode,
            onSubmitted: (value) {
              // textEditingController.clear();
              sendMessage(value);
              textEditingController.clear();
              focusNode.requestFocus();
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type out a message..."),
          ),
        ),
      ),
    ]);

    // if (shouldScroll) {
    //   _controller.jumpTo(_controller.position.maxScrollExtent);
    //   setState(() {
    //     shouldScroll = false;
    //   });
    // }
    return a;
  }
}
