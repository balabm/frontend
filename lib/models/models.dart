class UserInfo {
  final int? id;
  final String name;

  UserInfo({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class UploadedImage {
  final int? id;
  final String url;

  UploadedImage({this.id, required this.url});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
    };
  }
}

class AsrResponse {
  final int? id;
  final String response;

  AsrResponse({this.id, required this.response});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'response': response,
    };
  }
}

class LlmResponse {
  final int? id;
  final String response;

  LlmResponse({this.id, required this.response});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'response': response,
    };
  }
}
