import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart' as auth_io;

class GoogleSheetFetcher {
  final String _credentialsFile = 'assets/credentials.json';
  final String _spreadsheetId1 = '1r07cl4D-qZskyOAF62XX96C2yGmlRMGq4Fv7AwHQuis';
  final String _spreadsheetId2 = '16twU0HCETkHsMPWsa09Ze8aQERiDaKmwQ5SxFkUGGDw';

  // 인증 클라이언트를 저장할 static 변수
  static AutoRefreshingAuthClient? _authClient;

  // 구글 인증
  Future<AutoRefreshingAuthClient> _authenticate() async {
    try {
      // 이미 인증된 클라이언트가 있다면 재사용
      if (_authClient != null) {
        return _authClient!;
      }

      print('인증 시작...');
      final credentialsJson = await rootBundle.loadString(_credentialsFile);
      print('Credentials 파일 로드 성공');
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
      _authClient = await auth_io.clientViaServiceAccount(
          credentials, [sheets.SheetsApi.spreadsheetsScope]);
      print('인증 성공!');
      return _authClient!;
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

      // A4:D 대신 D4:G로 변경하여 키와 다국어 값을 포함하도록 수정
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
    try {
      final sheetData1 = await fetchSheetData(_spreadsheetId1, 'Signup');
      final sheetData2 = await fetchSheetData(_spreadsheetId2, 'Community');

      List<Map<String, String>> textDataList = [];

      // 데이터를 JSON 형식으로 변환
      for (var row in sheetData1) {
        if (row.length >= 4) {
          // 행에 충분한 데이터가 있는지 확인
          textDataList.add({
            "key": row[0],
            "kor": row[1],
            "eng": row[2],
            "jpn": row[3],
          });
        } else {
          print('경고: 잘못된 데이터 형식 (Signup): $row');
        }
      }

      // sheetData2 추가
      for (var row in sheetData2) {
        if (row.length >= 4) {
          // 행에 충분한 데이터가 있는지 확인
          textDataList.add({
            "key": row[0],
            "kor": row[1],
            "eng": row[2],
            "jpn": row[3],
          });
        } else {
          print('경고: 잘못된 데이터 형식 (Community): $row');
        }
      }

      // 원하는 언어로 필터링하여 JSON 포맷으로 생성
      Map<String, dynamic> jsonMap = {};
      for (var textData in textDataList) {
        String key = textData['key'] ?? ''; // null 체크 추가
        String value = textData[lang] ?? ''; // null 체크 추가
        if (key.isNotEmpty) {
          // 빈 키는 건너뛰기
          jsonMap[key] = value;
        }
      }

      return jsonEncode(jsonMap);
    } catch (e) {
      print('JSON 생성 중 오류 발생: $e');
      return jsonEncode({}); // 오류 발생 시 빈 JSON 객체 반환
    }
  }

  // 스프레드시트의 모든 시트 목록 가져오기
  Future<List<String>> getSheetList(String spreadsheetId) async {
    try {
      final client = await _authenticate();
      final sheetsApi = sheets.SheetsApi(client);

      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      return spreadsheet.sheets
              ?.map((sheet) => sheet.properties!.title!)
              .toList() ??
          [];
    } catch (e) {
      print('시트 목록 가져오기 실패: $e');
      rethrow;
    }
  }
}
