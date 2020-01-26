import 'dart:convert';

import 'package:http/http.dart' as http;

class JsonSender {
  static Future<String> createPost(String data) async {
    String url = 'https://jsonplaceholder.typicode.com/posts';
    print(data);
    return http.post(
      url,
      body: data,
      headers: {"Content-type": "application/json; charset=UTF-8"},
    ).then((http.Response response) {
      final int statusCode = response.statusCode;
      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return "Success";
    });
  }
}