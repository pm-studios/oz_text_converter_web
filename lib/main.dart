import 'package:flutter/material.dart';
import 'google_sheet_fetcher.dart';
import 'google_sheet_viewer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 544),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
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
        home: Builder(
          builder: (context) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(8.0),
              child: GoogleSheetViewer(),
            ),
          ),
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
