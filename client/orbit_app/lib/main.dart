import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:ui';
import 'dart:convert';

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
  WebSocketChannel? mcpChannel;
  
  bool isConnected = false;
  bool showKeyboard = true;
  bool showStatusDeck = false;
  double loadingProgress = 0;
  
  // MCP State
  String agentStatus = "OFFLINE";
  String currentTask = "No active connection";
  
  final TextEditingController urlController = TextEditingController(text: 'localhost:6901');

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
            _initMcpConnection();
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error de conexión: ${error.description}')),
            );
          },
        ),
      );
  }

  void _initMcpConnection() {
    // La IP del MCP server suele ser la misma que la del VNC pero en puerto 8000
    final host = urlController.text.split(':').first;
    final mcpUrl = 'ws://$host:8000/ws/mcp';
    
    try {
      mcpChannel = WebSocketChannel.connect(Uri.parse(mcpUrl));
      mcpChannel!.stream.listen((message) {
        final decoded = json.decode(message);
        if (decoded['type'] == 'STATE_UPDATE') {
          setState(() {
            agentStatus = decoded['data']['status'];
            currentTask = decoded['data']['current_task'];
          });
        } else if (decoded['type'] == 'ALERT') {
          _showSystemAlert(decoded['msg']);
        }
      }, onError: (err) {
        setState(() { agentStatus = "MCP ERROR"; });
      });
    } catch (e) {
      debugPrint("Fallo conexión MCP: $e");
    }
  }

  void _showSystemAlert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      )
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
    // Enviamos señal real al servidor MCP
    mcpChannel?.sink.add(json.encode({"type": "HALT_SIGNAL"}));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.yellowAccent),
            SizedBox(width: 10),
            Text('PÁNICO ENVIADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Se ha enviado la señal de interrupción al Planeta vía MCP. '
          'Todos los agentes de IA han sido forzados a HALT.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mcpChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ORBIT COCKPIT v2.0', 
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
            icon: Icon(Icons.analytics_outlined, color: showStatusDeck ? Colors.cyanAccent : Colors.white70),
            onPressed: () => setState(() => showStatusDeck = !showStatusDeck),
          ),
          IconButton(
            icon: Icon(showKeyboard ? Icons.keyboard_hide : Icons.keyboard, color: Colors.white70),
            onPressed: () => setState(() => showKeyboard = !showKeyboard),
          ),
        ],
      ),
      body: Stack(
        children: [
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
                  LinearProgressIndicator(value: loadingProgress, backgroundColor: Colors.white10, color: Colors.cyanAccent),
                
                _buildSystemStatusStrip(),

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
                
                if (showStatusDeck && isConnected) _buildAgentStatusDeck(),
                if (showKeyboard && isConnected) _buildDevKeyboard(),
              ],
            ),
          ),

          if (!isConnected) _buildConnectionOverlay(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusStrip() {
    if (!isConnected) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: agentStatus == "HALTED" ? Colors.red : Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: agentStatus == "HALTED" ? Colors.red : Colors.greenAccent, blurRadius: 4)]
                ),
              ),
              const SizedBox(width: 8),
              Text('AGENTE: $agentStatus', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const Text('ENLACE: ESTABLE', style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAgentStatusDeck() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11224D).withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.cyanAccent, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OBSERVATION DECK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const Divider(color: Colors.cyanAccent, thickness: 0.5),
          const SizedBox(height: 8),
          Text('TAREA ACTUAL:', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 4),
          Text(currentTask, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.white)),
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
                    const Text('ORBIT MISSION CONTROL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.cyanAccent),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        labelText: 'ID del Planeta (IP o URL)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _connect,
                        child: const Text('ENGAGE LINK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
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
                _DevKey(label: 'P', color: Colors.cyanAccent.withOpacity(0.1), onPressed: () {}),
                _DevKey(label: 'UNDO', onPressed: () {}),
                _DevKey(label: 'SAVE', onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _panicAction,
              icon: const Icon(Icons.bolt, color: Colors.yellowAccent),
              label: const Text('EMERGENCY HALT (PANIC)', style: TextStyle(fontWeight: FontWeight.bold)),
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
