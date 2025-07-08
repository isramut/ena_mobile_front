import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/chat/ena_mwinda_chat_page.dart';

class DraggableChatButton extends StatefulWidget {
  const DraggableChatButton({super.key});

  @override
  State<DraggableChatButton> createState() => _DraggableChatButtonState();
}

class _DraggableChatButtonState extends State<DraggableChatButton>
    with TickerProviderStateMixin {
  Offset position = Offset.zero;
  bool _isPositionInitialized = false;
  bool isDragging = false;
  bool isExpanded = false;
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();

    // Position initiale en bas à droite avec marge de sécurité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        // Position avec marge pour éviter le débordement - BOUTON ROND
        position = Offset(size.width - 80, size.height - 200);
        _isPositionInitialized = true;
      });
    });

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    if (isExpanded) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void _openFullChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EnaMwindaChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPositionInitialized) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // Largeur et hauteur adaptatives - TAILLE RÉDUITE
    final buttonWidth = isExpanded ? 280.0 : 60.0;
    final buttonHeight = isExpanded ? 320.0 : 60.0;

    // Contraindre la position pour éviter le débordement
    double constrainedX = position.dx.clamp(
      10.0,
      screenSize.width - buttonWidth - 10,
    );
    double constrainedY = position.dy.clamp(
      safePadding.top + 20,
      screenSize.height - buttonHeight - safePadding.bottom - 20,
    );

    return Positioned(
      left: constrainedX,
      top: constrainedY,
      child: GestureDetector(
        onTap: isExpanded ? null : _toggleExpansion,
        onPanStart: (details) {
          if (!isExpanded) {
            setState(() {
              isDragging = true;
            });
          }
        },
        onPanUpdate: (details) {
          if (!isExpanded && !isDragging) return;

          setState(() {
            position = Offset(
              (position.dx + details.delta.dx).clamp(
                10.0,
                screenSize.width - buttonWidth - 10,
              ),
              (position.dy + details.delta.dy).clamp(
                safePadding.top + 20,
                screenSize.height - buttonHeight - safePadding.bottom - 20,
              ),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            isDragging = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFF1C3D8F),
            borderRadius: BorderRadius.circular(isExpanded ? 20 : 30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: isExpanded ? 12 : 8,
                offset: isExpanded ? const Offset(0, 6) : const Offset(0, 4),
              ),
            ],
          ),
          child: isExpanded
              ? _buildExpandedContent()
              : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4), // Couleur bleu chat moderne
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(Icons.question_answer, color: Colors.white, size: 24),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Suppression complète du padding top
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec bouton fermer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.question_answer,
                color: Colors.white,
                size: 24,
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/ena_logo_blanc.png',
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description - plus compacte
          Expanded(
            flex: 2, // Limite l'espace
            child: Text(
              "Bonjour ! Je suis votre assistant virtuel ENA. Posez-moi vos questions sur l'École d'Administration.",
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // Bouton commencer - plus compact
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: _openFullChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3678FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Commencer la conversation",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
