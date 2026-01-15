import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // Required for IOWebSocketChannel
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io'; // Required for SecurityContext
import '../models/planet.dart';
import '../widgets/ai_chat_panel.dart'; // Import Chat Widget

void main() {
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Orbit Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: const Color(0xFF020205),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          primary: const Color(0xFF00FFFF),
          secondary: Colors.deepPurpleAccent,
        ),
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const HomeDashboard(),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final List<PlanetInstance> myPlanets = [
    // 10.0.2.2 is 'localhost' for Android Emulator. Use 'localhost' for Desktop/Web.
    PlanetInstance(id: '1', name: 'Antigravity Prime', url: '10.0.2.2:443'), 
  ];

  void _deployNewPlanet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando despliegue de instancia en Google Cloud...'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo Orbital
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_mission_control.png'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/logo_original.png', height: 40),
                              const SizedBox(width: 12),
                              Text(
                                'ORBIT',
                                style: GoogleFonts.orbitron(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'OPERACIONES DE CLOUD',
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 2),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: const Icon(Icons.person, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'PLANETAS ACTIVOS',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: myPlanets.length,
                      itemBuilder: (context, index) => _buildGlassPlanetCard(myPlanets[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDeployButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPlanetCard(PlanetInstance planet) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.public, color: Colors.cyanAccent.withOpacity(0.3), size: 40),
                const Icon(Icons.hub_outlined, color: Colors.cyanAccent, size: 24),
              ],
            ),
            title: Text(
              planet.name,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            subtitle: Text(
              planet.url,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CockpitView(planet: planet)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeployButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
        ),
        onPressed: _deployNewPlanet,
        child: Text(
          'DESPLEGAR NUEVO PLANETA',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class CockpitView extends StatefulWidget {
  final PlanetInstance planet;
  const CockpitView({super.key, required this.planet});

  @override
  State<CockpitView> createState() => _CockpitViewState();
}

class _CockpitViewState extends State<CockpitView> {
  late final WebViewController controller;
  WebSocketChannel? mcpChannel;
  
  bool isConnected = false;
  bool showKeyboard = true;
  bool showStatusDeck = false;
  bool showChat = false; // New Chat State
  bool isIdeMode = false; // IDE vs VNC Mode
  double loadingProgress = 0;
  
  String agentStatus = "OFFLINE";
  String currentTask = "Sin conexión activa";
  List<ChatMessage> chatMessages = []; // Chat History

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF050510))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => loadingProgress = p / 100),
          onPageFinished: (url) {
            setState(() => isConnected = true);
            _initMcpConnection();
          },
          // SSL ERROR BYPASS FOR SELF-SIGNED CERTS (ONLY FOR DEMO)
          onWebResourceError: (error) => debugPrint("Web Error: ${error.description}"),
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      );
    _loadContent();
  }

  void _loadContent() {
    final host = widget.planet.url.split(':').first;
    final port = widget.planet.url.split(':').last;
    final path = isIdeMode ? '/code/' : '/'; // Switch between VNC and IDE
    
    // NOTE: Android WebView might need user to install .p12 in OS Settings manually for mTLS to work here.
    final fullUrl = 'https://$host:$port$path';
    controller.loadRequest(Uri.parse(fullUrl));
  }

  void _toggleIdeMode() {
    setState(() {
      isIdeMode = !isIdeMode;
      _loadContent();
    });
  }

  Future<void> _initMcpConnection() async {
    final host = widget.planet.url.split(':').first;
    // ZERO TRUST SECURITY: Use WSS (Secure WebSocket) and mTLS
    // We connect to the Gateway (Port 443), not the exposed port.
    final mcpUrl = 'wss://$host:443/ws/mcp'; 

    try {
      // 1. Load Client Certificate (Identity)
      final ByteData data = await rootBundle.load('assets/client.p12');
      final SecurityContext context = SecurityContext(withTrustedRoots: true);
      context.useCertificateChainBytes(data.buffer.asUint8List(), password: "orbit123");
      context.usePrivateKeyBytes(data.buffer.asUint8List(), password: "orbit123");
      
      // 2. Create HttpClient with this Context
      final HttpClient client = HttpClient(context: context);
      client.badCertificateCallback = (cert, host, port) => true; // FIXME: Accept Self-Signed CA for Demo

      // 3. Connect Securely
      final WebSocket socket = await WebSocket.connect(mcpUrl, customClient: client);
      mcpChannel = IOWebSocketChannel(socket);

      // 4. Listen handling
      mcpChannel!.stream.listen((message) {
        final decoded = json.decode(message);
        if (decoded['type'] == 'STATE_UPDATE') {
          setState(() {
            agentStatus = decoded['data']['status'];
            currentTask = decoded['data']['current_task'];
            isConnected = true;
          });
        } else if (decoded['type'] == 'AI_RESPONSE') {
          // Add AI Message to Chat
          setState(() {
            chatMessages.add(ChatMessage(
              text: decoded['data']['text'], 
              isUser: false, 
              timestamp: DateTime.now()
            ));
            showChat = true; // Auto-open chat on response
          });
        }
      });
      
      debugPrint("✅ ZERO TRUST LINK ESTABLISHED");
    } catch (e) {
      debugPrint("❌ MCP Security Error: $e");
      setState(() {
        agentStatus = "AUTH_FAILED";
        currentTask = "Certificado Rechazado por Gateway";
      });
    }
  }

  void _panicAction() {
    mcpChannel?.sink.add(json.encode({"type": "HALT_SIGNAL"}));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('SISTEMA CONGELADO: Señal de Pánico Enviada'),
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
        title: Text(
          widget.planet.name.toUpperCase(),
          style: GoogleFonts.orbitron(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
             onPressed: _toggleIdeMode,
             child: Text(isIdeMode ? "IDE" : "VNC", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
          ),
          IconButton(
            icon: Icon(Icons.psychology, color: showChat ? Colors.cyanAccent : Colors.white),
            onPressed: () => setState(() => showChat = !showChat),
          ),
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: showStatusDeck ? Colors.cyanAccent : Colors.white),
            onPressed: () => setState(() => showStatusDeck = !showStatusDeck),
          ),
          IconButton(
            icon: Icon(showKeyboard ? Icons.keyboard_hide : Icons.keyboard),
            onPressed: () => setState(() => showKeyboard = !showKeyboard),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF020205)),
          SafeArea(
            child: Column(
              children: [
                if (loadingProgress < 1) 
                  LinearProgressIndicator(value: loadingProgress, color: Colors.cyanAccent, backgroundColor: Colors.black),
                _buildStatusStrip(),
                Expanded(child: WebViewWidget(controller: controller)),
                if (showStatusDeck) _buildAgentStatusDeck(),
                if (showChat) StartChatLayer(), // Replaced by Expanded Panel logic below
                if (showKeyboard) _buildDevKeyboard(),
              ],
            ),
          ),
          // Floating Chat Overlay (Outside standard Column to overlay keyboard if needed, or simply sit on top)
          if (showChat)
            Positioned(
              left: 20, right: 20, bottom: showKeyboard ? 160 : 20, top: 100,
              child: AIChatPanel(
                channel: mcpChannel, 
                messages: chatMessages, 
                onClose: () => setState(() => showChat = false)
              )
            ),
        ],
      ),
    );
  }

  // Helper placeholder for Column logic (removed in favor of Stack Positioned)
  Widget StartChatLayer() => const SizedBox.shrink(); 

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: agentStatus == "HALTED" ? Colors.red : Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: agentStatus == "HALTED" ? Colors.red : Colors.greenAccent,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AGENTE: $agentStatus',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const Text(
            'LNK: ESTABLE [12ms]',
            style: TextStyle(fontSize: 9, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentStatusDeck() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withOpacity(0.9),
            border: const Border(top: BorderSide(color: Colors.cyanAccent, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TELEMETRÍA DE CONTROL DE MISIÓN',
                style: GoogleFonts.orbitron(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                currentTask.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevKeyboard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF020205),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DevKeyShort(label: 'ESC'),
              _DevKeyShort(label: 'CTRL'),
              _DevKeyShort(label: 'ALT'),
              _DevKeyShort(label: 'TAB'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.warning_amber_rounded, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900.withOpacity(0.3),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
              onPressed: _panicAction,
              label: Text(
                'PÁNICO DE EMERGENCIA',
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevKeyShort extends StatelessWidget {
  final String label;
  const _DevKeyShort({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }
}
