import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:ui';
import 'dart:convert';
import '../models/planet.dart';

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
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF020205),
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
    PlanetInstance(id: '1', name: 'Alpha Station', url: 'localhost:6901'),
    PlanetInstance(id: '2', name: 'GCP Workstation 01', url: 'orbit.trycloudflare.com'),
  ];

  void _deployNewPlanet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando despliegue de instancia en Google Cloud...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.1,
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ORBIT CLOUD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          Text('Bienvenido, Wilmer', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text('MIS PLANETAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: myPlanets.length,
                      itemBuilder: (context, index) => _buildPlanetCard(myPlanets[index]),
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

  Widget _buildPlanetCard(PlanetInstance planet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.public, color: Colors.cyanAccent),
        title: Text(planet.name),
        subtitle: Text(planet.url, style: const TextStyle(fontSize: 10, color: Colors.white30)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CockpitView(planet: planet)),
          );
        },
      ),
    );
  }

  Widget _buildDeployButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _deployNewPlanet,
        child: const Text('DEPLOY NEW PLANET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
  double loadingProgress = 0;
  
  String agentStatus = "OFFLINE";
  String currentTask = "No active connection";

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
        ),
      );
    
    final fullUrl = widget.planet.url.startsWith('http') ? widget.planet.url : 'https://${widget.planet.url}';
    controller.loadRequest(Uri.parse(fullUrl));
  }

  void _initMcpConnection() {
    final host = widget.planet.url.split(':').first;
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
        }
      });
    } catch (e) {
      debugPrint("MCP Client Error: $e");
    }
  }

  void _panicAction() {
    mcpChannel?.sink.add(json.encode({"type": "HALT_SIGNAL"}));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.red, content: Text('SISTEMA CONGELADO: Señal de Pánico Enviada')),
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
        title: Text(widget.planet.name, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.transparent,
        actions: [
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
                if (loadingProgress < 1) LinearProgressIndicator(value: loadingProgress, color: Colors.cyanAccent),
                _buildStatusStrip(),
                Expanded(child: WebViewWidget(controller: controller)),
                if (showStatusDeck) _buildAgentStatusDeck(),
                if (showKeyboard) _buildDevKeyboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: agentStatus == "HALTED" ? Colors.red : Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('AGENT: $agentStatus', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Text('LATENCIA: 12ms', style: TextStyle(fontSize: 10, color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _buildAgentStatusDeck() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF0D1117), border: Border(top: BorderSide(color: Colors.cyanAccent))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('MISSION CONTROL TELEMETRY', style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(currentTask, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildDevKeyboard() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF020205),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DevKeyShort(label: 'ESC'), _DevKeyShort(label: 'CTRL'), _DevKeyShort(label: 'ALT'), _DevKeyShort(label: 'TAB'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              onPressed: _panicAction,
              child: const Text('EMERGENCY PANIC', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevKeyShort extends StatelessWidget {
  final String label;
        ),
      ),
    );
  }
}
