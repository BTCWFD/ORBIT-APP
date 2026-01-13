import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Orbit',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CockpitView(),
    );
  }
}

class CockpitView extends StatefulWidget {
  const CockpitView({super.key});

  @override
  State<CockpitView> createState() => _CockpitViewState();
}

class _CockpitViewState extends State<CockpitView> {
  late final WebViewController controller;
  bool isConnected = false;
  final TextEditingController urlController = TextEditingController(text: 'http://localhost:6901');

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              isConnected = true;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      );
  }

  void _connect() {
    controller.loadRequest(Uri.parse(urlController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orbit Cockpit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (!isConnected)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Connect to Planet Server'),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'Server URL'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _connect,
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // UI Overlay: Dev Keyboard
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DevKey(label: 'CTRL', onPressed: () {}),
                  _DevKey(label: 'ALT', onPressed: () {}),
                  _DevKey(label: 'ESC', onPressed: () {}),
                  _DevKey(label: 'TAB', onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.report_problem, color: Colors.red),
                    onPressed: () {
                      // Panic Button Logic
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevKey extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DevKey({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
