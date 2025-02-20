import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/sheets/v4.dart' as sheets;

class GoogleSheetFetcher {
  final String _credentialsFile =
      'assets/credentials.json'; // 앱 내에 JSON 인증 파일을 넣고 이를 사용
  final String _spreadsheetId1 = '1r07cl4D-qZskyOAF62XX96C2yGmlRMGq4Fv7AwHQuis';
  final String _spreadsheetId2 = '16twU0HCETkHsMPWsa09Ze8aQERiDaKmwQ5SxFkUGGDw';

  // 구글 인증
  Future<auth.AutoRefreshingAuthClient> _authenticate() async {
    final credentials =
        await auth.computeAuthenticationCredentialsFromJson(_credentialsFile);
    final client = await auth.clientViaServiceAccount(
        credentials, [sheets.SheetsApi.SpreadsheetsScope]);
    return client;
  }

  // 구글 시트에서 데이터 가져오기
  Future<List<List<String>>> fetchSheetData(
      String sheetId, String sheetName) async {
    final client = await _authenticate();
    final sheetsApi = sheets.SheetsApi(client);

    final response =
        await sheetsApi.spreadsheets.values.get(sheetId, '$sheetName!D4:G');
    final values = response.values;
    return values
            ?.map((row) => row.map((item) => item.toString()).toList())
            .toList() ??
        [];
  }

  // JSON 포맷으로 변환
  Future<String> generateJson(String lang) async {
    final sheetData1 = await fetchSheetData(_spreadsheetId1, 'Signup');
    final sheetData2 = await fetchSheetData(_spreadsheetId2, 'Community');

    List<Map<String, String>> textDataList = [];

    // 데이터를 JSON 형식으로 변환
    sheetData1.forEach((row) {
      textDataList.add({
        "key": row[0],
        "kor": row[1],
        "eng": row[2],
        "jpn": row[3],
      });
    });

    // sheetData2 추가
    sheetData2.forEach((row) {
      textDataList.add({
        "key": row[0],
        "kor": row[1],
        "eng": row[2],
        "jpn": row[3],
      });
    });

    // 원하는 언어로 필터링하여 JSON 포맷으로 생성
    Map<String, dynamic> jsonMap = {};
    for (var textData in textDataList) {
      String key = textData['key']!;
      jsonMap[key] = textData[lang]!;
    }

    return jsonEncode(jsonMap);
  }
}
