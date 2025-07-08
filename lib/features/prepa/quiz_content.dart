import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class QuizContent extends StatefulWidget {
  const QuizContent({super.key});

  @override
  State<QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<QuizContent>
    with TickerProviderStateMixin {
  // Configuration du quiz
  String selectedLevel = 'Débutant';
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

  // Questions statiques pour le prototype
  List<QuizQuestion> questions = [
    QuizQuestion(
      question:
          "Quelle est la capitale de la République Démocratique du Congo ?",
      options: ["Lubumbashi", "Kinshasa", "Goma", "Bukavu"],
      correctAnswer: "Kinshasa",
      explanation:
          "Kinshasa est la capitale et la plus grande ville de la RDC.",
    ),
    QuizQuestion(
      question: "En quelle année la RDC a-t-elle obtenu son indépendance ?",
      options: ["1958", "1960", "1962", "1965"],
      correctAnswer: "1960",
      explanation:
          "La RDC a obtenu son indépendance de la Belgique le 30 juin 1960.",
    ),
    QuizQuestion(
      question: "Qui était le premier président de la RDC ?",
      options: [
        "Mobutu Sese Seko",
        "Joseph Kasavubu",
        "Patrice Lumumba",
        "Laurent-Désiré Kabila",
      ],
      correctAnswer: "Joseph Kasavubu",
      explanation:
          "Joseph Kasavubu fut le premier président de la République du Congo (1960-1965).",
    ),
    QuizQuestion(
      question: "Quelle est la monnaie officielle de la RDC ?",
      options: ["Dollar américain", "Euro", "Franc congolais", "Dirham"],
      correctAnswer: "Franc congolais",
      explanation:
          "Le franc congolais (CDF) est la monnaie officielle de la RDC.",
    ),
    QuizQuestion(
      question: "Combien de provinces compte la RDC actuellement ?",
      options: ["11", "25", "26", "30"],
      correctAnswer: "26",
      explanation: "Depuis 2015, la RDC est divisée en 26 provinces.",
    ),
  ];

  final List<String> levels = ['Débutant', 'Intermédiaire', 'Avancé'];
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
  }

  @override
  void dispose() {
    timer?.cancel();
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void startQuiz() {
    setState(() {
      quizStarted = true;
      currentQuestionIndex = 0;
      score = 0;
      quizCompleted = false;
    });
    // Mélanger les questions et prendre le nombre sélectionné
    questions.shuffle();
    questions = questions.take(selectedQuestionCount).toList();
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

    if (answer == questions[currentQuestionIndex].correctAnswer) {
      score++;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                ),
                const SizedBox(height: 8),
                Text(
                  'Testez vos connaissances pour le concours ENA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
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
          Container(
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
                  Text(
                    'Question ${currentQuestionIndex + 1}/${questions.length}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
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
                  child: Text(
                    question.question,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                ),
                const SizedBox(height: 12),
                Text(
                  '$score/${questions.length} (${percentage}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  resultData['message'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
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
                _buildStatRow('Niveau', selectedLevel, const Color(0xFF8B5CF6)),
                _buildStatRow(
                  'Thématique',
                  selectedTheme,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Boutons d'action
          Column(
            children: [
              Container(
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
                      Text(
                        'Recommencer',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                      Text(
                        'Retour à la Préparation',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
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
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
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
          return InkWell(
            onTap: () => setState(() => selectedLevel = level),
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
                    onChanged: (value) =>
                        setState(() => selectedLevel = value!),
                    activeColor: theme.colorScheme.primary,
                  ),
                  Text(
                    level,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: themes.map((themeItem) {
          final isSelected = selectedTheme == themeItem;
          return InkWell(
            onTap: () => setState(() => selectedTheme = themeItem),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                border: Border(
                  bottom: themeItem != themes.last
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
                    onChanged: (value) =>
                        setState(() => selectedTheme = value!),
                    activeColor: theme.colorScheme.primary,
                  ),
                  Text(
                    themeItem,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF065F46),
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
              ),
            ),
            // Plus d'icône pour éviter toute confusion - pas de feedback immédiat
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          Container(
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
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}
