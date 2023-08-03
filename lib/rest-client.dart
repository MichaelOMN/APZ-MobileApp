import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MenuPair {
  int trainingId;
  String label;

  MenuPair({required this.trainingId, required this.label});
}

class RestClient {
  RestClient();

  Future<http.Response> fetchPong() async {
    http.Response resp =
        await http.get(Uri.parse("http://109.86.250.207:8070/ping"));
    return resp;
  }

  Future<http.Response> markAttendance(String jwtToken, int trainingId) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/api/attendance/"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken'
          },
          body: '{"training_id": $trainingId}');

      return resp;
    } on Exception catch (e) {
      return http.Response('$e', 408);
    }
  }

  Future<http.Response> signUpVisitor(
      String name, String email, String password) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/auth/visitor/sign-up"),
          headers: {'Content-Type': 'application/json'},
          body:
              '{"name": "$name", "email": "$email", "password": "$password"}');

      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }

  Future<http.Response> signUpCoach(
      String name, String email, String password) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/auth/coach/sign-up"),
          headers: {'Content-Type': 'application/json'},
          body:
              '{"name": "$name", "email": "$email", "password": "$password"}');
      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }

  Future<http.Response> signInVisitor(String username, String password) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/auth/visitor/sign-in"),
          headers: {'Content-Type': 'application/json'},
          body: '{"login": "$username", "password": "$password"}');
      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }

  Future<http.Response> signInCoach(String username, String password) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/auth/coach/sign-in"),
          headers: {'Content-Type': 'application/json'},
          body: '{"login": "$username", "password": "$password"}');
      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }

  Future<http.Response> deleteActivityUsage(
      String jwtToken, int activityUsageId) async {
    try {
      http.Response resp = await http.delete(
          Uri.parse(
              "http://109.86.250.207:8070/api/activity_usage/$activityUsageId"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken'
          });

      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }

  Future<Map<String, String>> getTrainings(String jwtToken) async {
    try {
      Map<String, String> menuPairs = {};

      http.Response resp = await http.get(
          Uri.parse("http://109.86.250.207:8070/api/trainings/"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken'
          });
      print("training response: ${resp.body}");

      if (resp.statusCode == 200) {
        dynamic bodyJSON = jsonDecode(resp.body);
        if (bodyJSON is List) {
          int i = 0;
          for (dynamic training = bodyJSON[i]; i < bodyJSON.length; i++) {
            int trainingId = training["id"];
            int clubId = training["club_id"];
            DateTime startTime = DateTime.parse(training["start"]);

            http.Response getClubResponse = await http.get(
                Uri.parse(
                    "http://109.86.250.207:8070/api/trainings/club/$clubId"),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $jwtToken'
                });

            if (getClubResponse.statusCode == 200) {
              dynamic clubBodyJSON = jsonDecode(getClubResponse.body);
              String clubName = clubBodyJSON['name'];
              var formatter = DateFormat('EEE dd/MM HH:mm:ss');
              var formatted = formatter.format(startTime);
              menuPairs.addAll({'${i + 1} - $clubName $formatted': trainingId.toString()});
            } else if (getClubResponse.statusCode == 500) {
              menuPairs.addAll({'ERROR getting': '-1'});
            }
          }
          return menuPairs;
        } else {
          throw Exception('Response body is not in correct format');
        }
      } else if (resp.statusCode == 500) {
        throw Exception('Server error: ${resp.body}');
      }
    } on Exception catch (e) {
      return {'ERROR: $e': '-1'};
    }
    return {};
  }

  Future<http.Response> sendActivityUsage(String jwtToken, String activityName,
      DateTime start, DateTime end, int trainingId) async {
    try {
      http.Response resp = await http.post(
          Uri.parse("http://109.86.250.207:8070/api/activity_usage/"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken'
          },
          body: ''' { "activity_name": "$activityName",
                    "start": "${start.toIso8601String()}",
                    "end": "${end.toIso8601String()}",
                    "training_id": $trainingId 
                  }
              ''');
      //print('Bearer $jwtToken');
      return resp;
    } on Exception catch (e) {
      return http.Response("$e", 408);
    }
  }
}
