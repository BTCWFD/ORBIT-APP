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
      String url = urlController.text;
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      controller.loadRequest(Uri.parse(url));
    }
  }

  void _panicAction() {
    // Lógica de Pánico: Simulación de parada de emergencia de agentes.
    // En la Fase 2, esto enviará una señal via MCP (Model Context Protocol).
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('PROTOCOLO DE PÁNICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Se ha enviado una señal de interrupción inmediata a todos los agentes activos en el Planeta. '
          'La ejecución se ha congelado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ORBIT COCKPIT v1.0', 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 13)),
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
            icon: Icon(showKeyboard ? Icons.keyboard_hide : Icons.keyboard, color: Colors.cyanAccent),
            onPressed: () => setState(() => showKeyboard = !showKeyboard),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
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
                  LinearProgressIndicator(
                    value: loadingProgress, 
                    backgroundColor: Colors.white10,
                    color: Colors.cyanAccent
                  ),
                
                Expanded(
                  child: Container(
                    margin: isConnected ? EdgeInsets.zero : const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: isConnected ? null : Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                      borderRadius: isConnected ? BorderRadius.zero : BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: isConnected ? BorderRadius.zero : BorderRadius.circular(20),
                      child: WebViewWidget(controller: controller),
                    ),
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
      child: SingleChildScrollView(
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
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch, size: 64, color: Colors.cyanAccent),
                    const SizedBox(height: 20),
                    const Text('ENLACE DE SATÉLITE', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Text('Proyecto Orbit v1.0', 
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 32),
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.cyanAccent),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        labelText: 'URL del Planeta (Cloudflare / Local)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                        ),
                        prefixIcon: const Icon(Icons.link, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          elevation: 10,
                          shadowColor: Colors.cyanAccent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _connect,
                        child: const Text('INICIAR SECUENCIA DE CONEXIÓN', 
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Asegúrate de que el túnel esté activo en Docker',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(top: BorderSide(color: Colors.cyanAccent.withOpacity(0.2))),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DevKey(label: 'ESC', color: Colors.redAccent.withOpacity(0.2), onPressed: () {}),
                _DevKey(label: 'CTRL', onPressed: () {}),
                _DevKey(label: 'ALT', onPressed: () {}),
                _DevKey(label: 'TAB', onPressed: () {}),
                _DevKey(label: 'CMD', onPressed: () {}),
                _DevKey(label: 'P', color: Colors.cyanAccent.withOpacity(0.1), onPressed: () {}), // Ctrl+P sim
                _DevKey(label: 'F1', onPressed: () {}),
                _DevKey(label: 'F12', onPressed: () {}),
                _DevKey(label: '/', onPressed: () {}),
                _DevKey(label: '|', onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1
                        )
                      ]
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: _panicAction,
                      icon: const Icon(Icons.bolt, color: Colors.yellowAccent),
                      label: const Text('PROTOCOLO DE PÁNICO', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
