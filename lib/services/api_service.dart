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

  // Logout but keep API key
  static void logoutKeepApiKey() {
    storage.remove('login_url');
    storage.remove('user_type');
    storage.remove('is_logged_in');
    // Note: We're NOT removing 'api_key' here
  }

  // Get Employee Registered Mobile Number
  static Future<Map<String, dynamic>?> getEmployeeRegisteredMobile(String login) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      var headers = {
        'ApiKey': apiKey,
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/GetEmployeeRegisteredMobile'));
      request.body = json.encode({
        "login": login,
        "pass": "string",
        "empid": "string",
        "mobile_no": "string",
        "value": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);

        // Extract data from the response structure
        if (responseData['statusCode'] == 'Success' &&
            responseData['data'] != null &&
            responseData['data'].isNotEmpty) {
          var employeeData = responseData['data'][0];
          return {
            'statusCode': responseData['statusCode'],
            'responseValue': 1,
            'mobile': employeeData['mobile_no'],
            'mobileNo': employeeData['mobile_no'],
            'mobile_no': employeeData['mobile_no'],
            'empid': employeeData['sid'] // Using sid as employee ID
          };
        }
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error getting employee mobile: $e');
      return null;
    }
  }

// Get Student Registered Mobile Number
  static Future<Map<String, dynamic>?> getStudentRegisteredMobile(String login) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      var headers = {
        'ApiKey': apiKey,
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/GetStudentRegisteredMobile'));
      request.body = json.encode({
        "login": login,
        "pass": "string",
        "sid": "string",
        "mobile_no": "string",
        "value": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);

        // Extract data from the response structure
        if (responseData['statusCode'] == 'Success' &&
            responseData['data'] != null &&
            responseData['data'].isNotEmpty) {
          var studentData = responseData['data'][0];
          return {
            'statusCode': responseData['statusCode'],
            'responseValue': 1,
            'mobile': studentData['mobile_no'],
            'mobileNo': studentData['mobile_no'],
            'mobile_no': studentData['mobile_no'],
            'sid': studentData['sid']
          };
        }
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error getting student mobile: $e');
      return null;
    }
  }

// Change Employee Password
  static Future<Map<String, dynamic>?> changeEmployeePassword(String login, String newPassword, String empId) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      String hash = generateHash(newPassword);

      var headers = {
        'ApiKey': apiKey,
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/ChangeEmployeePasswordData'));
      request.body = json.encode({
        "login": login,
        "pass": hash,
        "empid": empId,
        "mobile_no": "string",
        "value": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error changing employee password: $e');
      return null;
    }
  }

// Change Student Password
  static Future<Map<String, dynamic>?> changeStudentPassword(String login, String newPassword, String sid) async {
    try {
      String? apiKey = await getApiKey();
      if (apiKey == null) return null;

      String hash = generateHash(newPassword);

      var headers = {
        'ApiKey': apiKey,
        'Content-Type': 'application/json'
      };

      var request = http.Request('POST', Uri.parse('$baseUrl/ChangeStudentPassword'));
      request.body = json.encode({
        "login": login,
        "pass": hash,
        "sid": sid,
        "mobile_no": "string",
        "value": "string"
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseString);
        return responseData;
      }
      return null;
    } catch (e) {
      print('Error changing student password: $e');
      return null;
    }
  }
}
