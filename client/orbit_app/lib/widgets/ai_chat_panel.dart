import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AIChatPanel extends StatefulWidget {
  final WebSocketChannel? channel;
  final List<ChatMessage> messages;
  final VoidCallback onClose;

  const AIChatPanel({
    super.key, 
    required this.channel, 
    required this.messages, 
    required this.onClose
  });

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    if (widget.channel == null) return;

    final text = _controller.text;
    
    // Send to Server
    widget.channel!.sink.add(json.encode({
      "type": "AI_PROMPT",
      "payload": {"text": text}
    }));

    // Local Optimistic Update
    setState(() {
      widget.messages.add(ChatMessage(
        text: text, 
        isUser: true, 
        timestamp: DateTime.now()
      ));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050510).withOpacity(0.95),
            border: const Border(top: BorderSide(color: Colors.cyanAccent, width: 0.5)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ORBIT NEURAL LINK',
                          style: GoogleFonts.orbitron(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.cyanAccent,
                            letterSpacing: 2
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Chat Area
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: msg.isUser 
                              ? Colors.cyanAccent.withOpacity(0.1) 
                              : Colors.deepPurple.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(msg.isUser ? 12 : 2),
                            bottomRight: Radius.circular(msg.isUser ? 2 : 12),
                          ),
                          border: Border.all(
                            color: msg.isUser ? Colors.cyanAccent.withOpacity(0.3) : Colors.deepPurpleAccent.withOpacity(0.3),
                            width: 0.5
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.4
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                  color: Colors.black26,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        cursorColor: Colors.cyanAccent,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Escribe un comando o consulta...',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.cyanAccent),
                        onPressed: _sendMessage,
                        splashColor: Colors.cyanAccent.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
