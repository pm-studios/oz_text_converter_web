import 'package:flutter/material.dart';
import 'google_sheet_fetcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  List<String> _logs = [];
  List<SheetInfo> _allSheets = [];
  bool _loading = true;
  Map<String, List<String>> _translations = {}; // 키별 번역 데이터
  String? _selectedKey; // 선택된 키

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

  void _updatePreviewStyle(PreviewStyle newStyle) {
    setState(() {
      _previewStyle = newStyle;
    });
  }

  Widget _buildColorControls(
      String label, Color currentColor, Function(Color) onColorChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'HEX: #${currentColor.value.toRadixString(16).toUpperCase().substring(2)}'),
                  Text(
                      'RGB: ${currentColor.red}, ${currentColor.green}, ${currentColor.blue}'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('$label 선택'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: currentColor,
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
                      actions: <Widget>[
                        TextButton(
                          child: const Text('확인'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('색상 선택'),
            ),
          ],
        ),
      ],
    );
  }

  // 프리뷰 설정 패널
  Widget _buildStyleControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('프리뷰 설정', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('너비'),
                    Slider(
                      value: _previewStyle.width == double.infinity
                          ? 400
                          : _previewStyle.width,
                      min: 200,
                      max: 800,
                      divisions: 30,
                      label: _previewStyle.width == double.infinity
                          ? '∞'
                          : _previewStyle.width.round().toString(),
                      onChanged: (value) {
                        _updatePreviewStyle(PreviewStyle(
                          width: value,
                          height: _previewStyle.height,
                          borderRadius: _previewStyle.borderRadius,
                          backgroundColor: _previewStyle.backgroundColor,
                          textColor: _previewStyle.textColor,
                          fontSize: _previewStyle.fontSize,
                          fontFamily: _previewStyle.fontFamily,
                          padding: _previewStyle.padding,
                          fontWeight: _previewStyle.fontWeight,
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('높이'),
                    Slider(
                      value: _previewStyle.height,
                      min: 40,
                      max: 200,
                      divisions: 16,
                      label: _previewStyle.height.round().toString(),
                      onChanged: (value) {
                        _updatePreviewStyle(PreviewStyle(
                          width: _previewStyle.width,
                          height: value,
                          borderRadius: _previewStyle.borderRadius,
                          backgroundColor: _previewStyle.backgroundColor,
                          textColor: _previewStyle.textColor,
                          fontSize: _previewStyle.fontSize,
                          fontFamily: _previewStyle.fontFamily,
                          padding: _previewStyle.padding,
                          fontWeight: _previewStyle.fontWeight,
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('상하 패딩'),
                    Slider(
                      value: _previewStyle.padding.top,
                      min: 0,
                      max: 32,
                      divisions: 32,
                      label: _previewStyle.padding.top.round().toString(),
                      onChanged: (value) {
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
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('좌우 패딩'),
                    Slider(
                      value: _previewStyle.padding.left,
                      min: 0,
                      max: 32,
                      divisions: 32,
                      label: _previewStyle.padding.left.round().toString(),
                      onChanged: (value) {
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
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildColorControls(
                  '배경색',
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
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildColorControls(
                  '글자색',
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
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('폰트'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _previewStyle.fontFamily,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pretendard Variable',
                          child: Text(
                            'Pretendard',
                            style: TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Be Vietnam Pro',
                          child: Text(
                            'Be Vietnam Pro',
                            style: TextStyle(
                              fontFamily: 'Be Vietnam Pro',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('폰트 크기'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _previewStyle.fontSize,
                            min: 12,
                            max: 32,
                            divisions: 20,
                            label: _previewStyle.fontSize.round().toString(),
                            onChanged: (value) {
                              _updatePreviewStyle(PreviewStyle(
                                width: _previewStyle.width,
                                height: _previewStyle.height,
                                borderRadius: _previewStyle.borderRadius,
                                backgroundColor: _previewStyle.backgroundColor,
                                textColor: _previewStyle.textColor,
                                fontSize: value,
                                fontFamily: _previewStyle.fontFamily,
                                padding: _previewStyle.padding,
                                fontWeight: _previewStyle.fontWeight,
                              ));
                            },
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${_previewStyle.fontSize.round()}px',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('폰트 웨이트'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FontWeight>(
                      value: _previewStyle.fontWeight,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: FontWeight.w300, child: Text('Light (300)')),
                        DropdownMenuItem(
                            value: FontWeight.w400,
                            child: Text('Regular (400)')),
                        DropdownMenuItem(
                            value: FontWeight.w500,
                            child: Text('Medium (500)')),
                        DropdownMenuItem(
                            value: FontWeight.w600,
                            child: Text('SemiBold (600)')),
                        DropdownMenuItem(
                            value: FontWeight.w700, child: Text('Bold (700)')),
                        DropdownMenuItem(
                            value: FontWeight.w800,
                            child: Text('ExtraBold (800)')),
                      ],
                      onChanged: (FontWeight? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _updatePreviewStyle(PreviewStyle(
                              width: _previewStyle.width,
                              height: _previewStyle.height,
                              borderRadius: _previewStyle.borderRadius,
                              backgroundColor: _previewStyle.backgroundColor,
                              textColor: _previewStyle.textColor,
                              fontSize: _previewStyle.fontSize,
                              fontFamily: _previewStyle.fontFamily,
                              padding: _previewStyle.padding,
                              fontWeight: newValue,
                            ));
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllSheets();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().toString().split('.').first}] $message");
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _allSheets.length,
                          itemBuilder: (context, index) {
                            final sheet = _allSheets[index];
                            final isSelected = _selectedSheet == sheet.name;
                            return ListTile(
                              title: Text(
                                sheet.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withOpacity(0.15),
                              tileColor: isSelected
                                  ? Colors.blue.withOpacity(0.05)
                                  : null,
                              onTap: () =>
                                  _loadKeys(sheet.name, sheet.spreadsheetId),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // 중앙: 키 목록
              SizedBox(
                width: 250,
                child: Card(
                  child: _keys == null
                      ? const Center(
                          child: Text('시트를 선택해주세요'),
                        )
                      : ListView.builder(
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
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withOpacity(0.15),
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
        SizedBox(
          height: 200,
          child: Card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: const Row(
                    children: [
                      Text('로그 콘솔',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(_logs[_logs.length - 1 - index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
