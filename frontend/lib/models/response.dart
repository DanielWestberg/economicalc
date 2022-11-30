class Response {
  late String tokenType;
  late int expiresIn;
  late String accessToken;
  late String refreshToken;
  late String scope;
  late String idHint;

  Response(
      {required this.tokenType,
      required this.expiresIn,
      required this.accessToken,
      required this.refreshToken,
      required this.scope,
      required this.idHint});

  Response.fromJson(Map<String, dynamic> json) {
    tokenType = json['token_type'];
    expiresIn = json['expires_in'];
    accessToken = json['access_token'];
    refreshToken = json['refresh_token'];
    scope = json['scope'];
    idHint = json['id_hint'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['token_type'] = tokenType;
    data['expires_in'] = expiresIn;
    data['access_token'] = accessToken;
    data['refresh_token'] = refreshToken;
    data['scope'] = scope;
    data['id_hint'] = idHint;
    return data;
  }
}
