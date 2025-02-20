import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart' as auth_io;

class GoogleSheetFetcher {
  final String _credentialsFile = 'assets/credentials.json';
  final String _spreadsheetId1 = '1r07cl4D-qZskyOAF62XX96C2yGmlRMGq4Fv7AwHQuis';
  final String _spreadsheetId2 = '16twU0HCETkHsMPWsa09Ze8aQERiDaKmwQ5SxFkUGGDw';

  // 구글 인증
  Future<AutoRefreshingAuthClient> _authenticate() async {
    try {
      print('인증 시작...');
      final credentialsJson = await rootBundle.loadString(_credentialsFile);
      print('Credentials 파일 로드 성공');
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
      final client = await auth_io.clientViaServiceAccount(
          credentials, [sheets.SheetsApi.spreadsheetsScope]);
      print('인증 성공!');
      return client;
    } catch (e) {
      print('인증 실패: $e');
      rethrow;
    }
  }

  // 구글 시트에서 데이터 가져오기
  Future<List<List<String>>> fetchSheetData(
      String sheetId, String sheetName) async {
    try {
      print('시트 데이터 가져오기 시작: $sheetName');
      final client = await _authenticate();
      final sheetsApi = sheets.SheetsApi(client);

      final response =
          await sheetsApi.spreadsheets.values.get(sheetId, '$sheetName!D4:G');
      final values = response.values;
      print('시트 데이터 가져오기 성공: ${values?.length ?? 0}개 행');
      print('첫 번째 행 데이터: ${values?.firstOrNull}');
      return values
              ?.map((row) => row.map((item) => item.toString()).toList())
              .toList() ??
          [];
    } catch (e) {
      print('시트 데이터 가져오기 실패: $e');
      rethrow;
    }
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
