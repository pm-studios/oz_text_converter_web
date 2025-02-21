import 'package:flutter/material.dart';
import 'google_sheet_fetcher.dart';
import 'google_sheet_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FUZE 다국어 뷰어',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          background: const Color(0xFF2C2C2E),
          surface: const Color(0xFF3C3C3E),
          primary: Colors.blue,
        ),
        scaffoldBackgroundColor: const Color(0xFF2C2C2E),
        cardColor: const Color(0xFF3C3C3E),
        dividerColor: Colors.grey.shade700,
        useMaterial3: true,
      ),
      home: const Scaffold(
        // appBar 제거
        body: Padding(
          padding: EdgeInsets.all(8.0), // 패딩 16에서 8로 줄임
          child: GoogleSheetViewer(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final sheetFetcher = GoogleSheetFetcher();

  void _incrementCounter() async {
    String jsonOutput =
        await sheetFetcher.generateJson('eng'); // 'eng', 'kor', 'jpn'으로 선택
    print('Generated JSON: $jsonOutput');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
