import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

// 복수형 데이터를 위한 클래스를 최상위 레벨로 이동
class PluralTextData {
  String key;
  Map<String, String>? one;
  Map<String, String>? many;

  PluralTextData({required this.key, this.one, this.many});
}

class GoogleSheetFetcher {
  final String _spreadsheetId1 = '1r07cl4D-qZskyOAF62XX96C2yGmlRMGq4Fv7AwHQuis';
  final String _spreadsheetId2 = '16twU0HCETkHsMPWsa09Ze8aQERiDaKmwQ5SxFkUGGDw';

  // 구글 시트에서 데이터 가져오기
  Future<List<List<String>>> fetchSheetData(
      String sheetId, String sheetName) async {
    try {
      print('\x1B[36m시트 데이터 가져오기 시작: $sheetName\x1B[0m');
      String range = 'D4:G';

      final url =
          Uri.parse('https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?'
              'tqx=out:csv&sheet=$sheetName&range=$range');

      print('Fetching URL: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<List<String>> rows = [];
        try {
          final lines = LineSplitter.split(response.body);
          for (var line in lines) {
            if (line.trim().isEmpty) continue;

            List<String> cells = [];
            bool inQuotes = false;
            StringBuffer currentCell = StringBuffer();
            int cellIndex = 0; // 현재 처리 중인 셀의 인덱스

            // 문자 단위로 처리
            for (int i = 0; i < line.length; i++) {
              String char = line[i];

              if (char == '"') {
                if (i + 1 < line.length && line[i + 1] == '"') {
                  currentCell.write('"');
                  i++;
                } else {
                  inQuotes = !inQuotes;
                }
              } else if (char == ',' && !inQuotes) {
                // 셀 추가 전에 키 검증
                String cellValue = currentCell.toString().trim();
                if (cellIndex == 0 && !_isValidKey(cellValue)) {
                  // 첫 번째 셀(키)이 유효하지 않으면 이 행을 건너뜀
                  cells.clear();
                  break;
                }
                cells.add(cellValue);
                currentCell.clear();
                cellIndex++;
              } else {
                currentCell.write(char);
              }
            }

            // 마지막 셀 처리
            if (cells.isNotEmpty ||
                _isValidKey(currentCell.toString().trim())) {
              cells.add(currentCell.toString().trim());

              // 키가 유효한 경우에만 처리
              if (!cells.isEmpty && _isValidKey(cells[0])) {
                // 셀이 4개가 되도록 보장
                while (cells.length < 4) {
                  cells.add('');
                  print(
                      '\x1B[33m경고: [$sheetName] 키 "${cells[0]}"의 번역이 누락되었습니다.\x1B[0m');
                }

                print('\x1B[90mRow data (CSV): $cells\x1B[0m');
                rows.add(cells);
              }
            }
          }

          print('\x1B[32m시트 데이터 가져오기 성공: ${rows.length}개 행\x1B[0m');
          return rows;
        } catch (e) {
          print('\x1B[31mCSV 파싱 실패: $e\x1B[0m');
          rethrow;
        }
      } else {
        throw Exception('Failed to load sheet data: ${response.statusCode}');
      }
    } catch (e) {
      print('\x1B[31m시트 데이터 가져오기 실패: $e\x1B[0m');
      rethrow;
    }
  }

  // 키 유효성 검사 메서드 추가
  bool _isValidKey(String key) {
    if (key.isEmpty) return false;

    // 키는 영문, 숫자, 하이픈, 점만 포함해야 함
    final validKeyPattern = RegExp(r'^[a-zA-Z0-9\-\.]+$');

    // 키는 영문으로 시작해야 함
    final startsWithLetter = RegExp(r'^[a-zA-Z]');

    return validKeyPattern.hasMatch(key) && startsWithLetter.hasMatch(key);
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
      // 스프레드시트 ID별로 시트 목록 반환
      if (spreadsheetId == _spreadsheetId1) {
        return [
          'Signup',
          'Collection',
          'Space',
          'Rate',
          'Game Detail',
          'Search',
          'Message',
          'Notification',
        ];
      } else if (spreadsheetId == _spreadsheetId2) {
        return [
          'Community',
          'Onboarding',
          'Profile',
          'Rating Pitch',
          'Setting',
          'Report',
          'Refferal system',
        ];
      }

      print('Unknown spreadsheet ID: $spreadsheetId');
      return [];
    } catch (e) {
      print('시트 목록 가져오기 실패: $e');
      return [];
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
      print('\x1B[36mStarting to generate $fileName...\x1B[0m');
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

      print('\x1B[32mSuccessfully generated and downloaded $fileName\x1B[0m');
      print('\x1B[36mTotal keys: ${savedKeys.length}\x1B[0m');
      print('\x1B[36mTotal plural forms: ${pluralList.length}\x1B[0m');
    } catch (e, stackTrace) {
      print('\x1B[31mError generating $fileName:\x1B[0m');
      print('\x1B[31mError: $e\x1B[0m');
      print('\x1B[31mStack trace: $stackTrace\x1B[0m');
    }
  }

  Future<void> generateLocalizationKeyFile() async {
    try {
      print('\x1B[36mStarting to generate localization_key.dart...\x1B[0m');
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
          print('\x1B[33m중복 키 발견: $dartKey\x1B[0m');
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

      print(
          '\x1B[32mSuccessfully generated and downloaded localization_key.dart\x1B[0m');
      print('\x1B[36mTotal processed keys: $processedKeys\x1B[0m');
    } catch (e, stackTrace) {
      print('\x1B[31mError generating localization_key.dart:\x1B[0m');
      print('\x1B[31mError: $e\x1B[0m');
      print('\x1B[31mStack trace: $stackTrace\x1B[0m');
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
