import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'dart:html' as html;

// 복수형 데이터를 위한 클래스를 최상위 레벨로 이동
class PluralTextData {
  String key;
  Map<String, String>? one;
  Map<String, String>? many;

  PluralTextData({required this.key, this.one, this.many});
}

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

      // A4:D에서 D4:G로 변경 (4~7열 데이터를 가져오도록)
      final response =
          await sheetsApi.spreadsheets.values.get(sheetId, '$sheetName!D4:G');
      final values = response.values;
      print('시트 데이터 가져오기 성공: ${values?.length ?? 0}개 행');
      if (values?.isNotEmpty ?? false) {
        print('첫 번째 행 데이터: ${values?.first}');
      } else {
        print('가져온 데이터가 없습니다.');
      }
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

  // 모든 언어의 JSON 파일 생성
  Future<void> generateAllJsonFiles() async {
    await generateLanguageJson('kor', 'ko-KR.json');
    await generateLanguageJson('eng', 'en-US.json');
    await generateLanguageJson('jpn', 'ja-JP.json');
    await generateLocalizationKeyFile();
  }

  Future<void> generateLanguageJson(String lang, String fileName) async {
    try {
      print('Starting to generate $fileName...');
      final sheetData1 = await fetchSheetData(_spreadsheetId1, 'Signup');
      print('Fetched Signup sheet data: ${sheetData1.length} rows');
      final sheetData2 = await fetchSheetData(_spreadsheetId2, 'Community');
      print('Fetched Community sheet data: ${sheetData2.length} rows');

      final StringBuffer jsonString = StringBuffer();
      jsonString.writeln('{');

      Set<String> savedKeys = {};
      List<PluralTextData> pluralList = [];

      // 단수형 데이터 처리
      for (var data in [...sheetData1, ...sheetData2]) {
        if (data.length < 4 || data[0].isEmpty) continue;

        String key = data[0];
        if (key == "empty.key") continue;

        if (key.contains('.plural.')) {
          var index = key.lastIndexOf('.one');
          if (index > 0) {
            // one 형태의 복수형
            var baseKey = key.substring(0, index);
            pluralList.add(PluralTextData(
              key: baseKey,
              one: {lang: data[_getLangIndex(lang)]},
            ));
          } else {
            index = key.lastIndexOf('.many');
            if (index > 0) {
              // many 형태의 복수형
              var baseKey = key.substring(0, index);
              var pluralData = pluralList.firstWhere(
                (x) => x.key == baseKey,
                orElse: () => PluralTextData(key: baseKey),
              );
              pluralData.many = {lang: data[_getLangIndex(lang)]};
              if (!pluralList.contains(pluralData)) {
                pluralList.add(pluralData);
              }
            }
          }
        } else {
          if (savedKeys.contains(key)) continue;
          savedKeys.add(key);

          // 일반 키-값 쌍 추가
          jsonString.writeln(' "${key}": "${data[_getLangIndex(lang)]}",');
        }
      }

      // 복수형 데이터 처리
      for (var pluralData in pluralList) {
        if (savedKeys.contains(pluralData.key)) continue;
        savedKeys.add(pluralData.key);

        // 복수형 키는 camelCase로 변환
        String pluralKey = _convertToCamelCase(pluralData.key);
        jsonString.writeln(' "$pluralKey": {');

        if (pluralData.one != null) {
          jsonString.writeln('  "one": "${pluralData.one![lang]}",');
        }
        if (pluralData.many != null) {
          // many는 other로 변환
          jsonString.writeln('  "other": "${pluralData.many![lang]}"');
        }

        // 마지막 복수형이 아니면 쉼표 추가
        if (pluralList.indexOf(pluralData) < pluralList.length - 1) {
          jsonString.writeln(' },');
        } else {
          jsonString.writeln(' }');
        }
      }

      jsonString.writeln('}');

      // 파일 다운로드
      final blob = html.Blob([jsonString.toString()], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      print('Successfully generated and downloaded $fileName');
      print('Total keys: ${savedKeys.length}');
      print('Total plural forms: ${pluralList.length}');
    } catch (e, stackTrace) {
      print('Error generating $fileName:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> generateLocalizationKeyFile() async {
    try {
      print('Starting to generate localization_key.dart...');
      final sheetData1 = await fetchSheetData(_spreadsheetId1, 'Signup');
      print('Fetched Signup sheet data: ${sheetData1.length} rows');
      final sheetData2 = await fetchSheetData(_spreadsheetId2, 'Community');
      print('Fetched Community sheet data: ${sheetData2.length} rows');

      StringBuffer dart = StringBuffer();
      dart.writeln('class LocalizationKey {');
      Set<String> savedKeys = {};
      int processedKeys = 0;

      for (var data in [...sheetData1, ...sheetData2]) {
        if (data.length < 4 || data[0].isEmpty) {
          print('Skipping invalid row: $data');
          continue;
        }

        String key = data[0];
        String dartKey = key;

        if (key.contains('.plural.')) {
          print('Processing plural key: $key');
          if (key.contains('.one')) {
            dartKey = key.substring(0, key.lastIndexOf('.one'));
            dartKey = _convertToCamelCase(dartKey);
          } else {
            continue;
          }
        } else {
          dartKey = _convertToCamelCase(key);
        }

        if (savedKeys.contains(dartKey)) {
          print('Duplicate key found: $dartKey');
          continue;
        }
        savedKeys.add(dartKey);
        processedKeys++;

        String cleanEnglish = data[2].replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
        dart.writeln('  /// $cleanEnglish');
        dart.writeln('  static String $dartKey = "$key";');
      }

      dart.writeln('}');

      // Dart 파일 다운로드
      final blob = html.Blob([dart.toString()], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'localization_key.dart')
        ..click();
      html.Url.revokeObjectUrl(url);

      print('Successfully generated and downloaded localization_key.dart');
      print('Total processed keys: $processedKeys');
    } catch (e, stackTrace) {
      print('Error generating localization_key.dart:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handlePluralData(List<String> data, String key,
      List<PluralTextData> pluralList, String lang) {
    if (key.contains('.one')) {
      String baseKey = key.substring(0, key.lastIndexOf('.one'));
      pluralList.add(PluralTextData(
        key: baseKey,
        one: {'kor': data[1], 'eng': data[2], 'jpn': data[3]},
      ));
    } else if (key.contains('.many')) {
      String baseKey = key.substring(0, key.lastIndexOf('.many'));
      var existingPlural = pluralList.firstWhere(
        (element) => element.key == baseKey,
        orElse: () => PluralTextData(key: baseKey),
      );
      existingPlural.many = {'kor': data[1], 'eng': data[2], 'jpn': data[3]};
    }
  }

  String _convertToCamelCase(String input) {
    return input.toLowerCase().replaceAllMapped(
          RegExp(r'[-.](\w)'),
          (match) => match.group(1)!.toUpperCase(),
        );
  }

  int _getLangIndex(String lang) {
    switch (lang) {
      case 'kor':
        return 1; // 5열 (인덱스 1)
      case 'eng':
        return 2; // 6열 (인덱스 2)
      case 'jpn':
        return 3; // 7열 (인덱스 3)
      default:
        return 1;
    }
  }
}
