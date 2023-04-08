import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> requestData(
  String src,
  Map<String, String> headers,
  String username,
) async {
  final uri = Uri.parse(src);

  final response = await http.get(uri, headers: headers);

  if (response.statusCode != 200) {
    throw Exception('Failed to load page');
  }

  Map<String, dynamic> data = jsonDecode(response.body);
  return data;
}

Future downloadFiles(List items, String username) async {
  for (var items in items) {
    try {
      if (items["image_versions2"]["candidates"][0].length > 0) {
        downloadImage(items["image_versions2"]["candidates"][0]["url"], items["id"], username);
      }
    } catch (e) {}

    try {
      if (items["carousel_media"].length > 0) {
        for (var carousel in items["carousel_media"]) {
          downloadImage(
              carousel["image_versions2"]["candidates"][0]["url"], carousel["id"], username);
        }
      }
    } catch (e) {}
  }
}

Future checkNextImagesAndDownload(Map<String, dynamic> data, username) async {
  String nextMaxId = data["next_max_id"];
  String userId = data["user"]["pk_id"];
  final uri = 'https://www.instagram.com/api/v1/feed/user/$userId/?count=12&max_id=$nextMaxId';
  final Map<String, String> headers = {
    'Accept': '*/*',
    'Accept-Language': 'pt-BR,pt;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'Host': 'www.instagram.com',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15',
    'Referer': 'https://www.instagram.com/$username/',
    'Connection': 'keep-alive',
    'Cookie':
        'csrftoken=6K47eTq9KOx5Y0Pp5pmiwJxQJAnNeZGJ; ds_user_id=1182969977; rur="RVA\\0541182969977\\0541712455516:01f7e4f89df0399954bb5ada4051c6c32a9fd19df790d66ca9dfc40231c6cdc052600ea0"; sessionid=1182969977%3AiUm6Xs64Amb1fY%3A23%3AAYfIObVihdvxSOS6YuVzPB8K3Ao7wH4UquU-lRQsP9E; dpr=1; shbid="19221\\0541182969977\\0541712446078:01f79669649f84cd27ad3a3b0411022944abd0eaf5c9417cd5edb9f03b5fba0b2a1c958b"; shbts="1680910078\\0541182969977\\0541712446078:01f72d106dafe823850c2fb485f0f5c85adde14ec722c9b55423bfd53f621964104c1816"; datr=RjtkY6uDBWzGPloBa_mDUEQG; ig_did=06774091-F6B0-40A3-A82D-634B2299E88D; ig_nrcb=1; mid=YwuOTAAEAAE-xdEh7AlzNhH7uXQG',
    'X-ASBD-ID': '198387',
    'X-Requested-With': 'XMLHttpRequest',
    'X-IG-App-ID': '936619743392459',
    'X-IG-WWW-Claim': 'hmac.AR1XH1qyXtoHzE80H9pFQuOmsSPyNRsPsE_K7AxaHbPntmX_',
    'X-CSRFToken': '6K47eTq9KOx5Y0Pp5pmiwJxQJAnNeZGJ',
  };

  Map<String, dynamic> newData = await requestData(uri, headers, username);

  List items = newData["items"];

  downloadFiles(items, username);

  if (newData["more_available"]) {
    nextMaxId = newData["next_max_id"];
    checkNextImagesAndDownload(newData, username);
  }
}

Future getInstagramPhotos(String username) async {
  final String uri = 'https://www.instagram.com/api/v1/feed/user/$username/username/?count=12';

  final Map<String, String> headers = {
    'Accept': '*/*',
    'Accept-Language': 'pt-BR,pt;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'Host': 'www.instagram.com',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15',
    'Referer': 'https://www.instagram.com/$username/',
    'Connection': 'keep-alive',
    'X-IG-App-ID': '936619743392459',
  };

  Map<String, dynamic> data = await requestData(uri, headers, username);

  List items = data["items"];

  downloadFiles(items, username);

  if (data["more_available"]) {
    checkNextImagesAndDownload(data, username);
  }
}

Future downloadImage(String url, String filename, String folderName) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final directory = Directory.current;
    final folder = Directory('${directory.path}/$folderName');
    if (!await folder.exists()) {
      await folder.create();
    }
    final filePath = '${folder.path}/$filename.png';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  } else {
    throw Exception('Failed to download image');
  }
}

void main() {
  // Coloque o nome do usuário do instagram
  getInstagramPhotos('');
}
