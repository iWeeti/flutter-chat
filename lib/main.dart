import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rfid_sovellus/contact_select.dart';
import 'package:http/http.dart' as http;
import 'package:rfid_sovellus/login.dart';
import 'package:rfid_sovellus/settings.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import 'chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  final MaterialColor backgroundColor = const MaterialColor(0xFF616161, {
    50: Color.fromRGBO(97, 97, 97, .1),
    100: Color.fromRGBO(97, 97, 97, .2),
    200: Color.fromRGBO(97, 97, 97, .3),
    300: Color.fromRGBO(97, 97, 97, .4),
    400: Color.fromRGBO(97, 97, 97, .5),
    500: Color.fromRGBO(97, 97, 97, .6),
    600: Color.fromRGBO(97, 97, 97, .7),
    700: Color.fromRGBO(97, 97, 97, .8),
    800: Color.fromRGBO(97, 97, 97, .9),
    900: Color.fromRGBO(97, 97, 97, 1)
  });
  final MaterialColor errorColor = const MaterialColor(0xFFEA2B1F, {
    50: Color.fromRGBO(234, 43, 31, .1),
    100: Color.fromRGBO(234, 43, 31, .2),
    200: Color.fromRGBO(234, 43, 31, .3),
    300: Color.fromRGBO(234, 43, 31, .4),
    400: Color.fromRGBO(234, 43, 31, .5),
    500: Color.fromRGBO(234, 43, 31, .6),
    600: Color.fromRGBO(234, 43, 31, .7),
    700: Color.fromRGBO(234, 43, 31, .8),
    800: Color.fromRGBO(234, 43, 31, .9),
    900: Color.fromRGBO(63, 81, 181, 1)
  });
  final MaterialColor customColor = const MaterialColor(0xFF3F51B1, {
    50: Color.fromRGBO(63, 81, 177, .1),
    100: Color.fromRGBO(63, 81, 177, .2),
    200: Color.fromRGBO(63, 81, 177, .3),
    300: Color.fromRGBO(63, 81, 177, .4),
    400: Color.fromRGBO(63, 81, 177, .5),
    500: Color.fromRGBO(63, 81, 177, .6),
    600: Color.fromRGBO(63, 81, 177, .7),
    700: Color.fromRGBO(63, 81, 177, .8),
    800: Color.fromRGBO(63, 81, 177, .9),
    900: Color.fromRGBO(63, 81, 181, 1)
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => const LoginPage(),
        '/settings': (context) => const SettingsPage(),
      },
      title: 'Chat App',
      theme: ThemeData(
        primaryColor: customColor,
        bottomAppBarColor: customColor,
        // backgroundColor: backgroundColor,
        // cardColor: backgroundColor,
        colorScheme: const ColorScheme.light(),
      ),
      home: const MyHomePage(title: 'Chat App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final client = http.Client();
  final channel = WebSocketChannel.connect(Uri.parse("ws://weetisoft.xyz:9567"),
      protocols: ["chat-protocol"]);
  final int _pageCount = 2;
  final List<String> _pageNames = ["Contacts", "Chats"];
  int _pageIndex = 1;
  bool contactSelectOpen = false;
  late Future<List<int>> chats = Future<List<int>>(() {
    return [];
  });
  List<int> fetchedChats = [];
  String? username;
  String? pfp;
  bool pfpLoaded = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      String? token = value.getString("JWT");
      String? username = value.getString("username");
      setState(() {
        pfp = value.getString("profile_picture");
        pfpLoaded = true;
      });
      if (username != null) {
        this.username = username;
      }
      if (token == null) {
        return Navigator.pushNamed(context, '/login');
      }

      chats = fetchChats(token);
      channel.stream.listen((event) async {
        dynamic d = jsonDecode(event.toString());
        developer.log(d.toString(), name: "websocket");
        switch (d['t']) {
          case 0:
            channel.sink.add(jsonEncode({"t": 1, "token": token}));
            break;
          case 2:
            WSChat? chat = await WSChat.getChat(d['message']['chat_id']);
            if (chat != null) {
              await chat.addMessageFromJson(d['message']);
            } else {
              developer.log("Chat is null", name: "websocket");
            }
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(contactSelectOpen ? "Select Contact" : _pageNames[_pageIndex]),
        leading: contactSelectOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                      contactSelectOpen = false;
                    }))
            : null,
      ),
      bottomNavigationBar: _bottomNavigationBar(),
      drawer: _drawer(),
      body: contactSelectOpen ? const ContactSelect() : _body(),
      floatingActionButton: _actionButton(),
    );
  }

  Future<List<int>> fetchChats(String token) async {
    final response = await client
        .get(Uri.parse("http://weetisoft.xyz:9567/user/@me/chats"), headers: {
      HttpHeaders.authorizationHeader: token,
    });

    if (response.statusCode == 200) {
      for (var d in jsonDecode(response.body)['chats']) {
        fetchedChats.add(d['id']);
      }
      return fetchedChats;
    } else {
      throw response.body;
    }
  }

  FloatingActionButton _actionButton() {
    return FloatingActionButton(
      tooltip: "New Chat",
      onPressed: () {
        setState(() {
          Navigator.push(context,
              MaterialPageRoute(builder: (builder) => ContactSelect()));
        });
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _pfp() {
    if (pfpLoaded) {
      if (pfp == null) {
        return const Icon(Icons.person);
      }
      return CircleAvatar(
        backgroundImage: NetworkImage(pfp ?? ""),
      );
    }
    return const Icon(Icons.person);
  }

  Drawer _drawer() {
    return Drawer(
        child: ListView(children: [
      DrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _pfp(),
              ),
              Text(username ?? "Loading...")
            ],
          )),
      ListTile(
        title: const Text("Home"),
        selected: true,
        onTap: () {
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text("Settings"),
        onTap: () {
          Navigator.popAndPushNamed(context, "/settings");
        },
      ),
      ListTile(
        title: const Text("Log Out"),
        onTap: () {
          SharedPreferences.getInstance().then((value) {
            value.remove("JWT");
            value.remove("username");
            value.remove("user_id");
            Navigator.popAndPushNamed(context, "/login");
          });
        },
      )
    ]));
  }

  Widget _body() {
    // contacts
    if (_pageIndex == 0) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.all((25)),
                child: Text(
                  "Contacts",
                  style: TextStyle(fontSize: 36),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_pageIndex == 1) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FutureBuilder(
            future: chats,
            builder: (context, dynamic snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.all((25)),
                      child: Text(
                        "Chats",
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                    Expanded(
                      child: _chats(snapshot.data),
                    )
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}\n\n${snapshot.stackTrace}');
              }

              return Column(children: const <Widget>[
                Padding(
                  padding: EdgeInsets.all((25)),
                  child: Text(
                    "Chats",
                    style: TextStyle(fontSize: 36),
                  ),
                ),
                CircularProgressIndicator(),
              ]);
            },
          ),
        ),
      );
    }
    return const Text("bruh");
  }

  Widget _chats(data) {
    List<Widget> widgets = [];
    for (int chatId in data) {
      Future<WSChat?> chatFuture = WSChat.getChat(chatId);
      widgets.add(
        Card(
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Chat(chatId)));
            },
            child: FutureBuilder(
              future: chatFuture,
              builder: (context, dynamic snapshot) {
                if (snapshot.hasData) {
                  dynamic participants = snapshot.data.participants;
                  if (participants.length > 2) {
                    return const ListTile(
                        leading: Icon(Icons.group),
                        title: Text("Unnamed Group Chat"));
                  } else if (participants.length == 0) {
                    return const ListTile(
                        leading: Icon(Icons.error),
                        title: Text("Failed to load."));
                  } else {
                    for (var participant in participants) {
                      if (participant.username == username) continue;
                      var i;
                      if (participant.profilePicture == null) {
                        i = const Icon(Icons.person);
                      } else {
                        i = CircleAvatar(
                          backgroundImage:
                              NetworkImage(participant.profilePicture),
                        );
                      }
                      return ListTile(
                          leading: i, title: Text(participant.username));
                    }
                    var i;
                    var u = snapshot.data.participants[0];
                    if (u.profilePicture == null) {
                      i = const Icon(Icons.person);
                    } else {
                      i = CircleAvatar(
                        backgroundImage: NetworkImage(u.profilePicture),
                      );
                    }
                    return ListTile(leading: i, title: Text(u.username));
                  }
                }
                return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text("Loading..."));
              },
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: refreshChats,
      child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: data.length,
          itemBuilder: (context, index) => widgets[index]),
    );
  }

  BottomNavigationBar _bottomNavigationBar() {
    return BottomNavigationBar(
        currentIndex: _pageIndex,
        onTap: (value) {
          setState(() {
            _pageIndex = value;
          });
        },
        // backgroundColor: Colors.grey[700],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            tooltip: "Contacts",
            icon: Icon(Icons.contact_mail),
            label: "Contacts",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Chats"),
        ]);
  }

  Future<void> refreshChats() async {
    final prefs = await SharedPreferences.getInstance();
    fetchChats(prefs.getString("JWT") ?? "");
  }
}
