import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../services/ena_mwinda_chat_service.dart';
import '../../widgets/typing_dots_indicator.dart';

class EnaMwindaChatPage extends StatefulWidget {
  const EnaMwindaChatPage({super.key});

  @override
  State<EnaMwindaChatPage> createState() => _EnaMwindaChatPageState();
}

class _EnaMwindaChatPageState extends State<EnaMwindaChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Message de bienvenue d'ENA
    _messages.add(
      ChatMessage(
        text: EnaMwindaChatService.getWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Envoyer le message à ENA
      final response = await EnaMwindaChatService.sendMessage(userMessage);

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Désolé, une erreur s'est produite. Veuillez réessayer.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    
    // Gestion des zones système (navigation, clavier, etc.)
    final viewPadding = MediaQuery.paddingOf(context);
    final bottomSafeArea = math.max(viewPadding.bottom, 8.0);
    
    // Calculs responsifs
    final dynamicPadding = math.max(screenWidth * 0.04, 12.0);
    final logoWidth = math.min(screenWidth * 0.35, isSmallScreen ? 100.0 : 140.0);
    final logoHeight = math.min(screenHeight * 0.06, isSmallScreen ? 30.0 : 40.0);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFF1C3D8F),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.question_answer,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/images/ena_logo_blanc.png',
              width: logoWidth,
              height: logoHeight,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                EnaMwindaChatService.resetChat();
                _initializeChat();
              });
            },
            tooltip: "Nouvelle conversation",
          ),
        ],
      ),
      body: SafeArea(
        bottom: false, // On gère manuellement le bottom pour la navigation
        child: Column(
          children: [
            // Liste des messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(dynamicPadding),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator(screenWidth, screenHeight, isSmallScreen);
                  }
                  return _buildMessageBubble(_messages[index], screenWidth, screenHeight, isSmallScreen);
                },
              ),
            ),

            // Zone de saisie
            Container(
              padding: EdgeInsets.only(
                left: dynamicPadding,
                right: dynamicPadding,
                top: dynamicPadding,
                bottom: math.max(dynamicPadding, bottomSafeArea),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _buildInputArea(screenWidth, screenHeight, isSmallScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(double screenWidth, double screenHeight, bool isSmallScreen) {
    final borderRadius = isSmallScreen ? 20.0 : 24.0;
    final buttonSize = isSmallScreen ? 40.0 : 48.0;
    final spacing = math.max(screenWidth * 0.03, 8.0);
    final contentPadding = EdgeInsets.symmetric(
      horizontal: math.max(screenWidth * 0.04, 12.0),
      vertical: math.max(screenHeight * 0.015, 10.0),
    );
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: isSmallScreen ? "Question sur l'ENA..." : "Posez votre question sur l'ENA...",
              hintStyle: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: math.max(screenWidth * 0.035, 12.0),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF3678FF),
                  width: 2,
                ),
              ),
              contentPadding: contentPadding,
            ),
            maxLines: isSmallScreen ? 2 : null,
            style: GoogleFonts.poppins(
              fontSize: math.max(screenWidth * 0.04, 14.0),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: _isLoading ? Colors.grey : const Color(0xFF3678FF),
            elevation: isSmallScreen ? 4 : 6,
            child: _isLoading
                ? SizedBox(
                    width: buttonSize * 0.4,
                    height: buttonSize * 0.4,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: Colors.white,
                    size: buttonSize * 0.4,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double screenWidth, double screenHeight, bool isSmallScreen) {
    final maxBubbleWidth = math.min(
      screenWidth * (isSmallScreen ? 0.85 : 0.75),
      screenWidth - (screenWidth * 0.08), // Minimum padding
    );
    
    final borderRadius = isSmallScreen ? 16.0 : 18.0;
    final messageFontSize = math.max(screenWidth * 0.037, 13.0);
    final timestampFontSize = math.max(screenWidth * 0.028, 10.0);
    final bubblePadding = EdgeInsets.symmetric(
      horizontal: math.max(screenWidth * 0.04, 12.0),
      vertical: math.max(screenHeight * 0.015, 10.0),
    );
    final marginBottom = math.max(screenHeight * 0.015, 8.0);
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: bubblePadding,
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF3678FF)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(borderRadius).copyWith(
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : Radius.circular(borderRadius),
                  bottomLeft: message.isUser
                      ? Radius.circular(borderRadius)
                      : const Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  color: message.isUser
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: messageFontSize,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: math.max(screenHeight * 0.005, 2.0)),
            Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.poppins(
                fontSize: timestampFontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(double screenWidth, double screenHeight, bool isSmallScreen) {
    final borderRadius = isSmallScreen ? 16.0 : 18.0;
    final fontSize = math.max(screenWidth * 0.035, 12.0);
    final dotSize = math.max(screenWidth * 0.02, 6.0);
    final bubblePadding = EdgeInsets.symmetric(
      horizontal: math.max(screenWidth * 0.04, 12.0),
      vertical: math.max(screenHeight * 0.015, 10.0),
    );
    final marginBottom = math.max(screenHeight * 0.015, 8.0);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        padding: bubblePadding,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(borderRadius).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ENA écrit",
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: math.max(screenWidth * 0.02, 6.0)),
            TypingDotsIndicator(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey,
              dotSize: dotSize,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
