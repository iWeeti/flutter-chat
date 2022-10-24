import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool loading = false;
  late Future<bool> login;
  bool hasError = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Login"),
        leading: const Icon(Icons.login),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (hasError) {
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Column(
            children: [
              Card(
                  color: Theme.of(context).errorColor,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Error: ${error ?? "null"}"),
                  )),
              _form()
            ],
          )));
    }
    if (loading) {
      return FutureBuilder(builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          _form();
        }
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(child: CircularProgressIndicator()),
        );
      });
    }
    return _form();
  }

  Widget _form() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Center(child: Text("Login")),
          TextField(
            decoration: const InputDecoration(hintText: "Username"),
            controller: usernameController,
          ),
          TextField(
            decoration: const InputDecoration(hintText: "Password"),
            controller: passwordController,
            obscureText: true,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                  hasError = false;
                });
                try {
                  final response = await http.post(
                      Uri.parse("http://weetisoft.xyz:9567/auth/token"),
                      body: jsonEncode({
                        "username": usernameController.text,
                        "password": passwordController.text
                      }),
                      headers: {
                        HttpHeaders.contentTypeHeader: "application/json"
                      });
                  if (response.statusCode == 200) {
                    String token = jsonDecode(response.body)['token'];
                    final userResponse = await http.get(
                        Uri.parse("http://weetisoft.xyz:9567/user/@me"),
                        headers: {HttpHeaders.authorizationHeader: token});
                    developer.log(userResponse.statusCode.toString(),
                        name: "bruh");
                    if (userResponse.statusCode == 200) {
                      var user = jsonDecode(userResponse.body);
                      SharedPreferences.getInstance().then((value) {
                        value.setString("JWT", token);
                        value.setString("username", user['username']);
                        value.setInt("user_id", user['id']);
                        if (user['profilePicture'] != null) {
                          value.setString(
                              "profile_picture", user['profilePicture']);
                        } else {
                          value.remove("profile_picture");
                        }
                        setState(() {
                          loading = false;
                        });
                        Navigator.popAndPushNamed(context, "/");
                      });
                    } else {
                      throw Exception("Failed to get self user");
                    }
                  }
                } catch (exception) {
                  setState(() {
                    hasError = true;
                    error = exception.toString();
                    loading = false;
                  });
                }
              },
              child: const Text("Login"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                });
                try {
                  final response = await http.post(
                      Uri.parse("http://weetisoft.xyz:9567/auth/register"),
                      body: jsonEncode({
                        "username": usernameController.text,
                        "password": passwordController.text
                      }),
                      headers: {
                        HttpHeaders.contentTypeHeader: "application/json"
                      });
                  if (response.statusCode == 200) {
                    String token = jsonDecode(response.body)['token'];
                    final userResponse = await http.get(
                        Uri.parse("http://weetisoft.xyz:9567/user/@me"),
                        headers: {HttpHeaders.authorizationHeader: token});
                    developer.log(userResponse.statusCode.toString(),
                        name: "bruh");
                    if (userResponse.statusCode == 200) {
                      var user = jsonDecode(userResponse.body);
                      SharedPreferences.getInstance().then((value) {
                        value.setString("JWT", token);
                        value.setString("username", user['username']);
                        value.setInt("user_id", user['id']);
                        if (user['profilePicture'] != null) {
                          value.setString(
                              "profile_picture", user['profilePicture']);
                        } else {
                          value.remove("profile_picture");
                        }
                        setState(() {
                          loading = false;
                        });
                        Navigator.popAndPushNamed(context, "/");
                      });
                    } else {
                      throw Exception("Failed to get self user");
                    }
                  }
                } catch (exception) {
                  setState(() {
                    hasError = true;
                    error = exception.toString();
                    loading = false;
                  });
                }
              },
              child: const Text("Register"),
            ),
          )
        ],
      ),
    );
  }
}
