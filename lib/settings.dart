import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rfid_sovellus/user.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker imagePicker = ImagePicker();
  late Future<SelfUser> user;

  XFile? file = null;
  Uint8List? imageBytes;
  bool picked = false;

  @override
  void initState() {
    user = SelfUser.getSelfUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Settings"),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() {
                  Navigator.pop(context);
                })),
      ),
      body: FutureBuilder(
        future: user,
        builder: (context, dynamic snapshot) {
          if (snapshot.hasData) {
            String? username = snapshot.data?.username;
            return Column(children: [
              Text(username ?? "loading.."),
              Card(
                child: ListTile(
                  leading: _image(snapshot.data),
                  onTap: () async {
                    XFile? file = await imagePicker.pickImage(
                        source: ImageSource.gallery);
                    if (file == null) return;

                    this.file = file;
                    await snapshot.data.updateProfilePicture(file);
                    imageBytes = await file.readAsBytes();
                    setState(() {
                      picked = true;
                    });
                  },
                  // leading: Image(
                  //     image: NetworkImage(
                  //         "http://weetisoft.xyz:9567/media/$username")),
                  title: const Text("Change Profile Picture"),
                ),
              ),
            ]);
          }

          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _image(dynamic d) {
    if (d?.profilePicture != null) {
      return CircleAvatar(backgroundImage: NetworkImage(d.profilePicture));
    }

    return const Icon(Icons.person);
  }
}
