import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';

void main() {
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Orbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFF050510),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E).withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
  bool showKeyboard = true;
  double loadingProgress = 0;
  final TextEditingController urlController = TextEditingController(text: 'http://localhost:6901');

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF050510))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              isConnected = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error de conexión: ${error.description}')),
            );
          },
        ),
      );
  }

  void _connect() {
    if (urlController.text.isNotEmpty) {
      controller.loadRequest(Uri.parse(urlController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ORBIT COCKPIT v1.0', 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black26),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(showKeyboard ? Icons.keyboard_hide : Icons.keyboard),
            onPressed: () => setState(() => showKeyboard = !showKeyboard),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Aesthetic
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.5,
                colors: [Color(0xFF16213E), Color(0xFF050510)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                if (loadingProgress > 0 && loadingProgress < 1)
                  LinearProgressIndicator(value: loadingProgress, color: Colors.cyan),
                
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isConnected ? 0 : 20),
                    child: WebViewWidget(controller: controller),
                  ),
                ),
                
                if (showKeyboard && isConnected) _buildDevKeyboard(),
              ],
            ),
          ),

          if (!isConnected) _buildConnectionOverlay(),
        ],
      ),
    );
  }

  Widget _buildConnectionOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 48, color: Colors.cyanAccent),
                  const SizedBox(height: 20),
                  const Text('ENLACE DE SATÉLITE', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      labelText: 'URL del Planeta (VNC Server)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _connect,
                      child: const Text('CONECTAR AL SISTEMA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DevKey(label: 'ESC', color: Colors.redAccent.withOpacity(0.8), onPressed: () {}),
                _DevKey(label: 'CTRL', onPressed: () {}),
                _DevKey(label: 'ALT', onPressed: () {}),
                _DevKey(label: 'TAB', onPressed: () {}),
                _DevKey(label: 'CMD', onPressed: () {}),
                _DevKey(label: 'F1', onPressed: () {}),
                _DevKey(label: 'F12', onPressed: () {}),
                _DevKey(label: '/', onPressed: () {}),
                _DevKey(label: '|', onPressed: () {}),
                _DevKey(label: '-', onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.9),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('PÁNICO / HALT'),
                  ),
                ),
              ),
              _DevKey(label: 'UNDO', onPressed: () {}),
              _DevKey(label: 'SAVE', onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevKey extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  const _DevKey({required this.label, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
        ),
      ),
    );
  }
}
