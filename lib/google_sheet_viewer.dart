import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:collection/collection.dart';
import 'resizable_widget.dart';
import 'google_sheet_fetcher.dart';

// 로그 메시지를 위한 클래스를 최상위로 이동
class LogMessage {
  final DateTime timestamp;
  final String message;
  final Color? color;

  LogMessage({
    required this.timestamp,
    required this.message,
    this.color,
  });
}

// 시트 정보를 저장할 클래스
class SheetInfo {
  final String name;
  final String spreadsheetId;

  SheetInfo(this.name, this.spreadsheetId);
}

class PreviewStyle {
  final double width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color textColor;
  final String fontFamily;
  final double fontSize;
  final EdgeInsets padding;
  final FontWeight fontWeight;

  const PreviewStyle({
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.fontFamily = 'Pretendard Variable',
    this.fontSize = 16,
    this.padding = const EdgeInsets.all(8),
    this.fontWeight = FontWeight.w400,
  });
}

class PreviewComponent extends StatelessWidget {
  final String text;
  final PreviewStyle style;

  const PreviewComponent({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: style.padding,
      child: Text(
        text,
        style: TextStyle(
          color: style.textColor,
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
        ),
      ),
    );
  }
}

class GoogleSheetViewer extends StatefulWidget {
  const GoogleSheetViewer({super.key});

  @override
  State<GoogleSheetViewer> createState() => _GoogleSheetViewerState();
}

class _GoogleSheetViewerState extends State<GoogleSheetViewer> {
  final GoogleSheetFetcher _fetcher = GoogleSheetFetcher();
  List<String>? _keys;
  String _selectedSheet = '';
  List<LogMessage> _logs = [];
  List<SheetInfo> _allSheets = [];
  bool _loading = true;
  bool _loadingKeys = false;
  Map<String, List<String>> _translations = {};
  String? _selectedKey;

  // 스프레드시트 ID 목록
  final Map<String, String> _spreadsheets = {
    '시트1': '1r07cl4D-qZskyOAF62XX96C2yGmlRMGq4Fv7AwHQuis',
    '시트2': '16twU0HCETkHsMPWsa09Ze8aQERiDaKmwQ5SxFkUGGDw',
  };

  // 프리뷰 스타일 상태 관리
  PreviewStyle _previewStyle = const PreviewStyle(
    height: 80,
    borderRadius: 12,
    backgroundColor: Colors.white,
    textColor: Colors.black87,
    fontSize: 16,
  );

  // 시트 목록과 키 목록의 ScrollController 추가
  final ScrollController _sheetScrollController = ScrollController();
  final ScrollController _keyScrollController = ScrollController();

  // ScrollController 추가
  final ScrollController _logScrollController = ScrollController();

  void _updatePreviewStyle(PreviewStyle newStyle) {
    setState(() {
      _previewStyle = newStyle;
    });
  }

  Widget _buildStyleControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 첫 번째 줄: 너비, 높이, 패딩 설정
          Row(
            children: [
              // 너비
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('너비', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          '${_previewStyle.width == double.infinity ? '∞' : _previewStyle.width.round()}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                      child: Slider(
                        value: _previewStyle.width == double.infinity
                            ? 400
                            : _previewStyle.width,
                        min: 200,
                        max: 800,
                        divisions: 30,
                        onChanged: (value) => _updatePreviewStyle(PreviewStyle(
                          width: value,
                          height: _previewStyle.height,
                          borderRadius: _previewStyle.borderRadius,
                          backgroundColor: _previewStyle.backgroundColor,
                          textColor: _previewStyle.textColor,
                          fontSize: _previewStyle.fontSize,
                          fontFamily: _previewStyle.fontFamily,
                          padding: _previewStyle.padding,
                          fontWeight: _previewStyle.fontWeight,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 높이
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('높이', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          '${_previewStyle.height.round()}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                      child: Slider(
                        value: _previewStyle.height,
                        min: 40,
                        max: 200,
                        divisions: 16,
                        onChanged: (value) => _updatePreviewStyle(PreviewStyle(
                          width: _previewStyle.width,
                          height: value,
                          borderRadius: _previewStyle.borderRadius,
                          backgroundColor: _previewStyle.backgroundColor,
                          textColor: _previewStyle.textColor,
                          fontSize: _previewStyle.fontSize,
                          fontFamily: _previewStyle.fontFamily,
                          padding: _previewStyle.padding,
                          fontWeight: _previewStyle.fontWeight,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 패딩 부분 수정
              Expanded(
                child: Row(
                  children: [
                    // 상하 패딩
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('패딩 상하',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                '${_previewStyle.padding.vertical.round()}px',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                            child: Slider(
                              value: _previewStyle.padding.top,
                              min: 0,
                              max: 32,
                              divisions: 32,
                              onChanged: (value) =>
                                  _updatePreviewStyle(PreviewStyle(
                                width: _previewStyle.width,
                                height: _previewStyle.height,
                                borderRadius: _previewStyle.borderRadius,
                                backgroundColor: _previewStyle.backgroundColor,
                                textColor: _previewStyle.textColor,
                                fontSize: _previewStyle.fontSize,
                                fontFamily: _previewStyle.fontFamily,
                                padding: EdgeInsets.symmetric(
                                  vertical: value,
                                  horizontal: _previewStyle.padding.left,
                                ),
                                fontWeight: _previewStyle.fontWeight,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 좌우 패딩
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('패딩 좌우',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                '${_previewStyle.padding.horizontal.round()}px',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                            child: Slider(
                              value: _previewStyle.padding.left,
                              min: 0,
                              max: 32,
                              divisions: 32,
                              onChanged: (value) =>
                                  _updatePreviewStyle(PreviewStyle(
                                width: _previewStyle.width,
                                height: _previewStyle.height,
                                borderRadius: _previewStyle.borderRadius,
                                backgroundColor: _previewStyle.backgroundColor,
                                textColor: _previewStyle.textColor,
                                fontSize: _previewStyle.fontSize,
                                fontFamily: _previewStyle.fontFamily,
                                padding: EdgeInsets.symmetric(
                                  vertical: _previewStyle.padding.top,
                                  horizontal: value,
                                ),
                                fontWeight: _previewStyle.fontWeight,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 두 번째 줄: 폰트, 폰트 크기, 색상 설정
          Row(
            children: [
              // 폰트 선택
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: DropdownButtonFormField<String>(
                    value: _previewStyle.fontFamily,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pretendard Variable',
                        child:
                            Text('Pretendard', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'Be Vietnam Pro',
                        child: Text('Be Vietnam Pro',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _updatePreviewStyle(PreviewStyle(
                            width: _previewStyle.width,
                            height: _previewStyle.height,
                            borderRadius: _previewStyle.borderRadius,
                            backgroundColor: _previewStyle.backgroundColor,
                            textColor: _previewStyle.textColor,
                            fontSize: _previewStyle.fontSize,
                            fontFamily: newValue,
                            padding: _previewStyle.padding,
                            fontWeight: newValue == 'Be Vietnam Pro'
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ));
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 폰트 크기
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('폰트 크기', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          '${_previewStyle.fontSize.round()}px',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                      child: Slider(
                        value: _previewStyle.fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        onChanged: (value) => _updatePreviewStyle(PreviewStyle(
                          width: _previewStyle.width,
                          height: _previewStyle.height,
                          borderRadius: _previewStyle.borderRadius,
                          backgroundColor: _previewStyle.backgroundColor,
                          textColor: _previewStyle.textColor,
                          fontSize: value,
                          fontFamily: _previewStyle.fontFamily,
                          padding: _previewStyle.padding,
                          fontWeight: _previewStyle.fontWeight,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 색상 선택
              Expanded(
                child: Row(
                  children: [
                    _buildCompactColorControl(
                        '배경',
                        _previewStyle.backgroundColor,
                        (color) => _updatePreviewStyle(PreviewStyle(
                              width: _previewStyle.width,
                              height: _previewStyle.height,
                              borderRadius: _previewStyle.borderRadius,
                              backgroundColor: color,
                              textColor: _previewStyle.textColor,
                              fontSize: _previewStyle.fontSize,
                              fontFamily: _previewStyle.fontFamily,
                              padding: _previewStyle.padding,
                              fontWeight: _previewStyle.fontWeight,
                            ))),
                    const SizedBox(width: 4),
                    _buildCompactColorControl(
                        '글자',
                        _previewStyle.textColor,
                        (color) => _updatePreviewStyle(PreviewStyle(
                              width: _previewStyle.width,
                              height: _previewStyle.height,
                              borderRadius: _previewStyle.borderRadius,
                              backgroundColor: _previewStyle.backgroundColor,
                              textColor: color,
                              fontSize: _previewStyle.fontSize,
                              fontFamily: _previewStyle.fontFamily,
                              padding: _previewStyle.padding,
                              fontWeight: _previewStyle.fontWeight,
                            ))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactColorControl(
      String label, Color color, Function(Color) onColorChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(label),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: onColorChanged,
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsvWithHue,
                    pickerAreaBorderRadius:
                        const BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('확인'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
          child: const Text('선택', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllSheets();
  }

  void _addLog(String message, {Color? color}) {
    setState(() {
      _logs.add(LogMessage(
        timestamp: DateTime.now(),
        message: message,
        color: color,
      ));
    });
  }

  Future<void> _loadAllSheets() async {
    setState(() {
      _loading = true;
      _allSheets = [];
    });

    try {
      for (var entry in _spreadsheets.entries) {
        final sheets = await _fetcher.getSheetList(entry.value);
        _allSheets.addAll(
            sheets.map((sheetName) => SheetInfo(sheetName, entry.value)));
        _addLog('${entry.key}에서 ${sheets.length}개의 시트를 불러왔습니다.');
      }
    } catch (e) {
      _addLog('시트 목록 로딩 실패: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadKeys(String sheetName, String sheetId) async {
    setState(() {
      _selectedSheet = sheetName;
      _keys = null;
      _translations = {};
      _selectedKey = null;
    });

    try {
      final data = await _fetcher.fetchSheetData(sheetId, sheetName);
      setState(() {
        // 키와 번역 데이터 저장
        _translations = {};
        for (var row in data) {
          if (row.length >= 4 && row[0].isNotEmpty) {
            _translations[row[0]] = [
              row.length > 1 ? row[1] : '', // 한국어
              row.length > 2 ? row[2] : '', // 영어
              row.length > 3 ? row[3] : '', // 일본어
            ];
          }
        }
        _keys = _translations.keys.toList();
      });
      _addLog('$sheetName 시트에서 ${_keys?.length ?? 0}개의 키를 불러왔습니다.');
    } catch (e) {
      _addLog('키 로딩 실패: $e');
    }
  }

  // Map 비교 함수 추가
  bool _areTranslationsEqual(
      Map<String, List<String>> a, Map<String, List<String>> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key]!.length != b[key]!.length) return false;
      for (var i = 0; i < a[key]!.length; i++) {
        if (a[key]![i] != b[key]![i]) return false;
      }
    }

    return true;
  }

  Future<void> _refreshCurrentSheet() async {
    if (_selectedSheet.isEmpty) return;

    final currentSheet = _allSheets.firstWhere(
      (sheet) => sheet.name == _selectedSheet,
      orElse: () => SheetInfo('', ''),
    );

    if (currentSheet.spreadsheetId.isEmpty) return;

    setState(() {
      _loadingKeys = true;
    });

    try {
      final data = await _fetcher.fetchSheetData(
          currentSheet.spreadsheetId, currentSheet.name);

      final previousTranslations = _translations;
      final previousKey = _selectedKey;

      setState(() {
        _translations = {};
        for (var row in data) {
          if (row.length >= 4 && row[0].isNotEmpty) {
            _translations[row[0]] = [
              row.length > 1 ? row[1] : '',
              row.length > 2 ? row[2] : '',
              row.length > 3 ? row[3] : '',
            ];
          }
        }
        _keys = _translations.keys.toList();

        if (previousKey != null && _translations.containsKey(previousKey)) {
          _selectedKey = previousKey;
        } else {
          _selectedKey = null;
        }
      });

      _addLog('$_selectedSheet 시트 새로고침 완료 (${_keys?.length ?? 0}개의 키)');

      if (!_areTranslationsEqual(previousTranslations, _translations)) {
        _addLog('시트 데이터가 변경되었습니다.');
      } else {
        _addLog('시트 데이터에 변경사항이 없습니다.');
      }
    } catch (e) {
      _addLog('새로고침 실패: $e');
    } finally {
      setState(() {
        _loadingKeys = false;
      });
    }
  }

  // 유효성 검증 메서드 추가
  Future<void> _validateAllSheets() async {
    if (_allSheets.isEmpty) return;

    _addLog('🔍 유효성 검증 시작...');
    setState(() {
      _loading = true;
    });

    try {
      Map<String, Map<String, List<String>>> allSheetData = {};

      // 시트 데이터 로딩 진행률 표시
      for (var i = 0; i < _allSheets.length; i++) {
        var sheet = _allSheets[i];
        _addLog(
            '📊 진행률: ${((i + 1) / _allSheets.length * 100).round()}% - ${sheet.name} 로딩 중...');

        final data =
            await _fetcher.fetchSheetData(sheet.spreadsheetId, sheet.name);
        Map<String, List<String>> translations = {};
        for (var row in data) {
          if (row.length >= 4 && row[0].isNotEmpty) {
            translations[row[0]] = [
              row.length > 1 ? row[1] : '',
              row.length > 2 ? row[2] : '',
              row.length > 3 ? row[3] : '',
            ];
          }
        }
        allSheetData[sheet.name] = translations;
      }

      Set<String> allKeys = {};
      allSheetData.values.forEach((translations) {
        allKeys.addAll(translations.keys);
      });

      int totalKeys = allKeys.length;
      int checkedKeys = 0;
      int issueCount = 0;
      bool hasIssues = false; // 변수 선언 추가

      for (String key in allKeys) {
        checkedKeys++;
        if (checkedKeys % 100 == 0) {
          // 100개마다 진행률 표시
          _addLog('🔍 키 검증 진행률: ${(checkedKeys / totalKeys * 100).round()}%');
        }

        Map<String, List<String>> keyTranslations = {};

        // 각 시트에서 해당 키의 번역을 수집
        for (var entry in allSheetData.entries) {
          if (entry.value.containsKey(key)) {
            keyTranslations[entry.key] = entry.value[key]!;
          }
        }

        // 번역이 있는 시트들끼리 비교
        if (keyTranslations.length > 1) {
          var firstSheet = keyTranslations.entries.first;
          for (var entry in keyTranslations.entries.skip(1)) {
            for (int i = 0; i < 3; i++) {
              if (firstSheet.value[i] != entry.value[i]) {
                hasIssues = true;
                issueCount++;
                String language = i == 0 ? "한국어" : (i == 1 ? "영어" : "일본어");
                _addLog('⚠️ 불일치 발견: 키 "$key"',
                    color: const Color(0xFFE65100)); // 진한 주황색
                _addLog(
                    '  - ${firstSheet.key}: $language = "${firstSheet.value[i]}"',
                    color: const Color(0xFF795548)); // 갈색
                _addLog('  - ${entry.key}: $language = "${entry.value[i]}"',
                    color: const Color(0xFF795548)); // 갈색
              }
            }
          }
        }
      }

      // 최종 결과 표시
      if (!hasIssues) {
        _addLog('✅ 검증 완료: 총 $totalKeys개의 키에서 문제가 발견되지 않았습니다.',
            color: Colors.green);
      } else {
        _addLog('❌ 검증 완료: 총 $totalKeys개의 키 중 $issueCount개의 불일치가 발견되었습니다.',
            color: Colors.red);
      }
    } catch (e) {
      _addLog('❌ 유효성 검증 실패: $e', color: Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 로그 표시 위젯 수정
  Widget _buildLogItem(LogMessage log) {
    String? text;
    if (log.message.startsWith('  - ')) {
      // "  - 시트명: 언어 = "텍스트"" 형식에서 텍스트 추출
      final match = RegExp(r'  - (.*?): .* = "(.*?)"').firstMatch(log.message);
      if (match != null) {
        final sheetName = match.group(1);
        text = match.group(2);

        return InkWell(
          onTap: () async {
            if (sheetName != null && text != null) {
              // 해당 시트 선택
              final sheet = _allSheets.firstWhere(
                (s) => s.name == sheetName,
                orElse: () => SheetInfo('', ''),
              );

              if (sheet.name.isNotEmpty) {
                await _loadKeys(sheet.name, sheet.spreadsheetId);

                // 해당 텍스트를 포함하는 키 찾기
                final keyWithText = _translations.entries.firstWhere(
                  (entry) => entry.value.contains(text),
                  orElse: () => MapEntry('', []),
                );

                if (keyWithText.key.isNotEmpty) {
                  setState(() {
                    _selectedKey = keyWithText.key;
                  });
                }
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.message,
              style: TextStyle(
                color: log.color ?? Colors.black87,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        );
      }
    }

    // 일반 로그 메시지
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        log.message,
        style: TextStyle(
          color: log.color ?? Colors.black87,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // 좌측: 시트 목록
              SizedBox(
                width: 180,
                child: Card(
                  child: Column(
                    children: [
                      // 시트 목록 헤더 부분 수정
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('시트 목록',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: '모든 시트 유효성 검증',
                                  onPressed: _validateAllSheets,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 시트 목록
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _sheetScrollController,
                                itemCount: _allSheets.length,
                                itemBuilder: (context, index) {
                                  final sheet = _allSheets[index];
                                  final isSelected =
                                      _selectedSheet == sheet.name;
                                  return ListTile(
                                    title: Text(
                                      sheet.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedTileColor:
                                        Colors.blue.withOpacity(0.15),
                                    tileColor: isSelected
                                        ? Colors.blue.withOpacity(0.05)
                                        : null,
                                    onTap: () => _loadKeys(
                                        sheet.name, sheet.spreadsheetId),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 중앙: 키 목록
              SizedBox(
                width: 250,
                child: Card(
                  child: Column(
                    children: [
                      // 새로고침 버튼을 키 목록 상단으로 이동
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('키 목록',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: '키 목록 새로고침',
                              onPressed: _selectedSheet.isEmpty
                                  ? null
                                  : () => _refreshCurrentSheet(),
                            ),
                          ],
                        ),
                      ),
                      // 키 목록
                      Expanded(
                        child: _keys == null
                            ? const Center(
                                child: Text('시트를 선택해주세요'),
                              )
                            : _loadingKeys
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ListView.builder(
                                    controller: _keyScrollController,
                                    itemCount: _keys?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      final key = _keys![index];
                                      final isSelected = _selectedKey == key;
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          key,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.black,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedTileColor:
                                            Colors.blue.withOpacity(0.15),
                                        tileColor: isSelected
                                            ? Colors.blue.withOpacity(0.05)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedKey = key;
                                          });
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 우측: 선택된 키의 번역 (프리뷰)
              Expanded(
                child: Card(
                  child: _selectedKey == null
                      ? const Center(
                          child: Text('키를 선택해주세요'),
                        )
                      : Column(
                          children: [
                            _buildStyleControls(),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PreviewComponent(
                                      text:
                                          _translations[_selectedKey]?[0] ?? '',
                                      style: _previewStyle,
                                    ),
                                    const SizedBox(height: 16),
                                    PreviewComponent(
                                      text:
                                          _translations[_selectedKey]?[1] ?? '',
                                      style: _previewStyle,
                                    ),
                                    const SizedBox(height: 16),
                                    PreviewComponent(
                                      text:
                                          _translations[_selectedKey]?[2] ?? '',
                                      style: _previewStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        // 하단: 로그 콘솔
        ResizableWidget(
          child: SizedBox(
            height: 200, // 초기 높이
            child: Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('로그 콘솔',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: '로그 지우기',
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: true,
                      ),
                      child: ListView.builder(
                        controller: _logScrollController,
                        physics: const ClampingScrollPhysics(),
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final realIndex = _logs.length - 1 - index;
                          if (realIndex < 0 || realIndex >= _logs.length)
                            return null;
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildLogItem(_logs[realIndex]),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          onResize: (height) {
            // 최소 100px, 최대 500px로 제한
            return height.clamp(100.0, 500.0);
          },
        ),
      ],
    );
  }
}
