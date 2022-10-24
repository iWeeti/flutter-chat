import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfUser extends WSUser {
  // SelfUser(super.id, super.username);
  SelfUser(WSUser user) : super(user.id, user.username, user.profilePicture);

  Future<String> updateProfilePicture(XFile file) async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("JWT");
    if (token == null) return "";
    FormData formData = FormData.fromMap(
        {"profilePicture": MultipartFile.fromBytes(await file.readAsBytes())});
    final response = await dio.post(
      "http://weetisoft.xyz:9567/user/@me/profile-picture",
      options: Options(headers: {
        "Authorization": token,
        "Content-Type": "application/x-www-form-urlencoded"
      }),
      data: formData,
    );

    // dynamic jsonData = jsonDecode(response.data);
    String url = response.data['profilePicture'];
    profilePicture = url;
    (await SharedPreferences.getInstance()).setString("profile_picture", url);
    return url;
    // (await WSUser.getUser(id)).profilePicture =
    //     jsonDecode(response.body)['profilePicture'];
  }

  static Future<SelfUser> getSelfUser() async {
    final prefs = await SharedPreferences.getInstance();
    WSUser? wsUser = await WSUser.getUser(prefs.getInt("user_id") ?? -1);
    return SelfUser(wsUser!);
  }
}

class WSUser {
  static Map<int, WSUser> cache = {};
  static Future<WSUser?> getUser(int id) async {
    if (cache.containsKey(id)) {
      return cache[id];
    }

    final prefs = await SharedPreferences.getInstance();

    final response = await http
        .get(Uri.parse("http://weetisoft.xyz:9567/user/$id"), headers: {
      HttpHeaders.authorizationHeader: prefs.getString("JWT") ?? ""
    });
    return fromJson(response.body);
  }

  int id;
  String username;
  String? profilePicture = "";

  WSUser(this.id, this.username, this.profilePicture);

  static WSUser fromJson(String data) {
    dynamic d = jsonDecode(data);
    var user = WSUser(d['id'], d['username'], d['profilePicture']);
    return user;
  }
}
