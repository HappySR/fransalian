import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:crypto/crypto.dart';

class ApiService {
  static const String baseUrl = 'https://api.realitypublicschool.in/api';
  static const String clientCode = '68634';
  static final GetStorage storage = GetStorage();

  // Get API Key
  static Future<String?> getApiKey() async {
    try {
      // Check if API key is already stored
      String? storedApiKey = storage.read('api_key');
      if (storedApiKey != null && storedApiKey.isNotEmpty) {
        return storedApiKey;
      }

      // If not stored, fetch from API
      var headers = {
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/GetApikey'));
      request.body = json.encode({
        "client_code": clientCode
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);

        if (responseData['statusCode'] == 'Success') {
          String apiKey = responseData['apiKey'];
          // Store API key for future use
          storage.write('api_key', apiKey);
          return apiKey;
        }
      }
      return null;
    } catch (e) {
      print('Error getting API key: $e');
      return null;
    }
  }

  // Generate hash for password
  static String generateHash(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Student Login
  static Future<Map<String, dynamic>?> studentLogin(String username, String password) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      String hash = generateHash(password);

      var headers = {
        'Content-Type': 'application/json',
        'APIKey': apiKey
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/studentloginsoap'));
      request.body = json.encode({
        "userid": 0,
        "empid": 0,
        "login": username,
        "hash": hash,
        "mobileno": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);

        if (responseData['responseValue'] == 1) {
          // Store login URL and user type
          storage.write('login_url', responseData['responseString']);
          storage.write('user_type', 'student');
          storage.write('is_logged_in', true);
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print('Error in student login: $e');
      return null;
    }
  }

  // Employee Login
  static Future<Map<String, dynamic>?> employeeLogin(String username, String password) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      String hash = generateHash(password);

      var headers = {
        'Content-Type': 'application/json',
        'APIKey': apiKey
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/employeeloginsoap'));
      request.body = json.encode({
        "userid": 0,
        "empid": 0,
        "login": username,
        "hash": hash,
        "mobileno": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);

        if (responseData['responseValue'] == 1) {
          // Store login URL and user type
          storage.write('login_url', responseData['responseString']);
          storage.write('user_type', 'employee');
          storage.write('is_logged_in', true);
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print('Error in employee login: $e');
      return null;
    }
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return storage.read('is_logged_in') ?? false;
  }

  // Get stored login URL
  static String? getLoginUrl() {
    return storage.read('login_url');
  }

  // Logout
  static void logout() {
    storage.remove('login_url');
    storage.remove('user_type');
    storage.remove('is_logged_in');
  }
}
