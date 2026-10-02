import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/app_exception.dart';
import '../utils/config.dart';

/// Shared HTTP client. Turns network and server failures into
/// [AppException]s with messages that can be shown to the user.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {'Accept': 'application/json', 'User-Agent': AppConfig.userAgent};

  Future<dynamic> getJson(Uri uri, {Duration timeout = const Duration(seconds: 20)}) =>
      _send(() => _client.get(uri, headers: _headers), timeout);

  Future<dynamic> postForm(Uri uri, Map<String, String> body, {Duration timeout = const Duration(seconds: 20)}) =>
      _send(() => _client.post(uri, headers: _headers, body: body), timeout);

  Future<dynamic> _send(Future<http.Response> Function() request, Duration timeout) async {
    http.Response res;
    try {
      res = await request().timeout(timeout);
    } on SocketException {
      throw const AppException('No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw const AppException('The service took too long to respond. Please try again.');
    } on http.ClientException {
      throw const AppException('Could not reach the service. Check your connection and try again.');
    }
    if (res.statusCode == 429) {
      throw const AppException('The service is busy right now. Please wait a minute and try again.');
    }
    if (res.statusCode >= 500) {
      throw const AppException('The service is temporarily unavailable. Please try again later.');
    }
    if (res.statusCode >= 400) {
      throw AppException('The request was rejected (error ${res.statusCode}).');
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const AppException('The service sent an unexpected response.');
    }
  }
}
