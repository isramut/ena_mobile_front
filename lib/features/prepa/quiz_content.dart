import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ena_mobile_front/models/quiz_models.dart';
import 'package:ena_mobile_front/services/quiz_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'dart:async';

class QuizContent extends StatefulWidget {
  const QuizContent({super.key});

  @override
  State<QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<QuizContent>
    with TickerProviderStateMixin {
  
  // État de chargement des données API
  bool isLoadingData = true;
  bool hasError = false;
  String errorMessage = '';
  QuizResponse? quizResponse;
  List<QuizModule> availableModules = [];
  QuizModule? selectedModule;
  
  // Configuration du quiz
  String selectedLevel = 'debutant'; // Changé pour correspondre à l'API
  String selectedTheme = 'Culture Générale';
  int selectedQuestionCount = 10;

  // État du quiz
  bool quizStarted = false;
  bool quizCompleted = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 45; // secondes par question
  Timer? timer;
  String? selectedAnswer;
  bool answerSubmitted = false;

  // Animation
  late AnimationController _progressController;
  late AnimationController _cardController;

  // Questions provenant de l'API (plus de questions statiques !)
  List<QuizQuestion> questions = []; // Maintenant vide, sera rempli par l'API

  // Listes de configuration (adaptées pour l'API)
  final List<String> levels = ['debutant', 'moyen', 'avance']; // Noms API
  final List<String> levelDisplayNames = ['Débutant', 'Moyen', 'Avancé']; // Affichage
  final List<String> themes = [
    'Culture Générale',
    'Droit Public',
    'Économie',
    'Histoire de la RDC',
    'Gestion Publique',
    'Institutions',
  ];
  final List<int> questionCounts = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Charger les données depuis l'API
    _loadQuizData();
  }

  /// Charge les données du quiz depuis l'API
  Future<void> _loadQuizData() async {
    setState(() {
      isLoadingData = true;
      hasError = false;
    });

    try {
      final result = await QuizApiService.getQuizModulesWithCache();
      
      if (result['success'] == true) {
        final QuizResponse response = result['data'];
        setState(() {
          quizResponse = response;
          availableModules = response.modules.where((m) => m.isActive).toList();
          isLoadingData = false;
          
          // Sélectionner le premier module du niveau sélectionné
          _updateSelectedModule();
        });
        
        print('✅ Quiz data loaded: ${availableModules.length} modules');
      } else {
        setState(() {
          isLoadingData = false;
          hasError = true;
          errorMessage = result['error'] ?? 'Erreur lors du chargement';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingData = false;
        hasError = true;
        errorMessage = 'Erreur de connexion: $e';
      });
    }
  }

  /// Met à jour le module sélectionné selon le niveau et le thème
  void _updateSelectedModule() {
    final modulesForLevel = availableModules.where((m) => 
      m.level == selectedLevel && 
      m.title.toLowerCase().contains(selectedTheme.toLowerCase())
    ).toList();
    
    // Si aucun module ne correspond au thème exact, prendre le premier du niveau
    if (modulesForLevel.isEmpty) {
      final fallbackModules = availableModules.where((m) => m.level == selectedLevel).toList();
      selectedModule = fallbackModules.isNotEmpty ? fallbackModules.first : null;
    } else {
      selectedModule = modulesForLevel.first;
    }
    
    print('📚 Module sélectionné: ${selectedModule?.title ?? 'Aucun'}');
    print('🎯 Niveau: $selectedLevel, Thème: $selectedTheme');
  }

  @override
  void dispose() {
    timer?.cancel();
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void startQuiz() {
    // Vérifier qu'un module est sélectionné
    if (selectedModule == null || selectedModule!.questions.isEmpty) {
      _showError('Aucun module sélectionné ou module vide');
      return;
    }

    setState(() {
      quizStarted = true;
      currentQuestionIndex = 0;
      score = 0;
      quizCompleted = false;
    });
    
    // Utiliser les questions du module sélectionné depuis l'API
    questions = List.from(selectedModule!.questions);
    questions.shuffle();
    questions = questions.take(selectedQuestionCount).toList();
    
    print('🎯 Quiz démarré: ${selectedModule!.title}');
    print('📝 Questions: ${questions.length}');
    
    _startTimer();
  }

  void _startTimer() {
    timeLeft = 45;
    _progressController.reset();
    _progressController.forward();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _submitAnswer(null); // Temps écoulé
        }
      });
    });
  }

  void _submitAnswer(String? answer) {
    if (answerSubmitted) return;

    timer?.cancel();
    setState(() {
      selectedAnswer = answer;
      answerSubmitted = true;
    });

    // Vérifier si la réponse est correcte en comparant avec l'index de l'option correcte
    if (answer != null) {
      final currentQuestion = questions[currentQuestionIndex];
      final answerIndex = currentQuestion.options.indexOf(answer);
      if (answerIndex == currentQuestion.correctOption) {
        score++;
      }
    }

    // Attendre 1 seconde avant de passer à la question suivante (sans afficher le résultat)
    Future.delayed(const Duration(seconds: 1), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        answerSubmitted = false;
      });
      _startTimer();
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    timer?.cancel();
    setState(() {
      quizCompleted = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      quizStarted = false;
      quizCompleted = false;
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswer = null;
      answerSubmitted = false;
    });
    timer?.cancel();
    _progressController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quiz Préparation ENA',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: !quizStarted
            ? _buildSetupScreen()
            : quizCompleted
            ? _buildResultScreen()
            : _buildQuizScreen(),
      ),
    );
  }

  Widget _buildSetupScreen() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    
    // Affichage du chargement
    if (isLoadingData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement du quiz...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    // Affichage d'erreur
    if (hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuizData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.quiz, size: 60, color: theme.colorScheme.onPrimary),
                const SizedBox(height: 16),
                Text(
                  'Quiz de Préparation',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Testez vos connaissances pour le concours ENA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Configuration du quiz
          _buildConfigSection('Niveau de difficulté', Icons.trending_up),
          const SizedBox(height: 8),
          _buildLevelSelector(),

          const SizedBox(height: 24),

          _buildConfigSection('Thématique', Icons.category),
          const SizedBox(height: 8),
          _buildThemeSelector(),

          const SizedBox(height: 24),

          _buildConfigSection(
            'Nombre de questions',
            Icons.format_list_numbered,
          ),
          const SizedBox(height: 8),
          _buildQuestionCountSelector(),

          const SizedBox(height: 32),

          // Informations du quiz
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFFDEF7EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Text(
                      'Informations du quiz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF10B981)
                            : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('⏱️', '45 secondes par question'),
                _buildInfoRow('🎯', 'Questions à choix multiples'),
                _buildInfoRow('📊', 'Score final avec analyse'),
                _buildInfoRow('🔄', 'Possibilité de recommencer'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton de démarrage
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Commencer le Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header avec progression
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Question ${currentQuestionIndex + 1}/${questions.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTimerColor(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${timeLeft}s',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.outline.withValues(
                  alpha: 0.3,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ],
          ),
        ),

        // Question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:                  Text(
                    question.question,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: null, // Permet plusieurs lignes
                    overflow: TextOverflow.visible,
                  ),
                ),

                const SizedBox(height: 24),

                // Options de réponse
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnswerOption(option, index),
                  );
                }).toList(),

                // Message d'attente après sélection (sans révéler la bonne réponse)
                if (answerSubmitted) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Question suivante...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E3A8A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final percentage = (score / questions.length * 100).round();
    final resultData = _getResultData(percentage);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Résultat principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: resultData['color'],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(resultData['icon'], size: 80, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  resultData['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  '$score/${questions.length} (${percentage}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  resultData['message'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Statistiques détaillées
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques détaillées',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Questions correctes',
                  '$score',
                  const Color(0xFF10B981),
                ),
                _buildStatRow(
                  'Questions incorrectes',
                  '${questions.length - score}',
                  const Color(0xFFEF4444),
                ),
                _buildStatRow(
                  'Taux de réussite',
                  '$percentage%',
                  const Color(0xFF3B82F6),
                ),
                _buildStatRow('Niveau', _getDisplayLevel(selectedLevel), const Color(0xFF8B5CF6)),
                _buildStatRow(
                  'Thématique',
                  _getTruncatedTheme(selectedTheme),
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Boutons d'action
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _resetQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Recommencer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Retour à la Préparation',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Méthodes utilitaires pour l'UI

  Widget _buildConfigSection(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: levels.map((level) {
          final isSelected = selectedLevel == level;
          final displayName = levelDisplayNames[levels.indexOf(level)];
          return InkWell(
            onTap: () {
              setState(() {
                selectedLevel = level;
                _updateSelectedModule();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                border: Border(
                  bottom: level != levels.last
                      ? BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: level,
                    groupValue: selectedLevel,
                    onChanged: (value) {
                      setState(() {
                        selectedLevel = value!;
                        _updateSelectedModule();
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final theme = Theme.of(context);
    
    // Générer les thèmes disponibles depuis les modules de l'API
    final availableThemes = availableModules
        .map((module) => module.title)
        .toSet()
        .toList()
        ..sort();
    
    // Si aucun thème disponible, utiliser les thèmes par défaut
    final themesToShow = availableThemes.isNotEmpty ? availableThemes : themes;
    
    // S'assurer que le thème sélectionné est dans la liste
    if (!themesToShow.contains(selectedTheme) && themesToShow.isNotEmpty) {
      selectedTheme = themesToShow.first;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: themesToShow.map((themeItem) {
          final isSelected = selectedTheme == themeItem;
          return InkWell(
            onTap: () {
              setState(() {
                selectedTheme = themeItem;
                _updateSelectedModule();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                border: Border(
                  bottom: themeItem != themesToShow.last
                      ? BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        )
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: themeItem,
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() {
                        selectedTheme = value!;
                        _updateSelectedModule();
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      themeItem,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: questionCounts.map((count) {
          final isSelected = selectedQuestionCount == count;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedQuestionCount = count),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A8A) : null,
                  border: Border(
                    right: count != questionCounts.last
                        ? const BorderSide(color: Color(0xFFE5E7EB))
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF065F46),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String option, int index) {
    final letters = ['A', 'B', 'C', 'D'];
    final isSelected = selectedAnswer == option;

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF374151);

    // Après sélection, on montre seulement que l'option est sélectionnée (sans indiquer si c'est correct)
    if (isSelected) {
      backgroundColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
      borderColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF1E3A8A);
    }

    return InkWell(
      onTap: answerSubmitted ? null : () => _submitAnswer(option),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letters[index],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: null, // Permet plusieurs lignes
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (timeLeft > 30) return const Color(0xFF10B981);
    if (timeLeft > 15) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Map<String, dynamic> _getResultData(int percentage) {
    if (percentage >= 80) {
      return {
        'title': 'Excellent !',
        'message': 'Vous maîtrisez parfaitement le sujet. Continuez ainsi !',
        'color': const Color(0xFF10B981),
        'icon': Icons.emoji_events,
      };
    } else if (percentage >= 60) {
      return {
        'title': 'Bien joué !',
        'message': 'Bon niveau, mais vous pouvez encore progresser.',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.thumb_up,
      };
    } else if (percentage >= 40) {
      return {
        'title': 'Peut mieux faire',
        'message': 'Il faut réviser davantage pour améliorer vos résultats.',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.psychology,
      };
    } else {
      return {
        'title': 'À retravailler',
        'message': 'Reprenez les cours et recommencez le quiz.',
        'color': const Color(0xFFEF4444),
        'icon': Icons.school,
      };
    }
  }
  
  void _showError(String message) {
    ErrorPopup.show(
      context,
      title: 'Erreur',
      message: message,
    );
  }

  /// Méthodes utilitaires pour la responsivité

  /// Affiche le niveau de manière lisible
  String _getDisplayLevel(String level) {
    switch (level) {
      case 'debutant':
        return 'Débutant';
      case 'moyen':
        return 'Moyen';
      case 'avance':
        return 'Avancé';
      default:
        return level;
    }
  }

  /// Tronque le nom du thème s'il est trop long
  String _getTruncatedTheme(String theme) {
    if (theme.length <= 20) return theme;
    return '${theme.substring(0, 17)}...';
  }
}


