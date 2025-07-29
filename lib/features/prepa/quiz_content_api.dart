import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ena_mobile_front/models/quiz_models.dart';
import 'package:ena_mobile_front/services/quiz_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'dart:async';

class QuizContentWithApi extends StatefulWidget {
  const QuizContentWithApi({super.key});

  @override
  State<QuizContentWithApi> createState() => _QuizContentWithApiState();
}

class _QuizContentWithApiState extends State<QuizContentWithApi>
    with TickerProviderStateMixin {
  
  // État de chargement des données
  bool isLoadingData = true;
  bool hasError = false;
  String errorMessage = '';
  QuizResponse? quizResponse;
  List<QuizModule> availableModules = [];
  
  // Configuration du quiz
  QuizModule? selectedModule;
  String selectedLevel = 'debutant';
  
  // État du quiz
  bool quizStarted = false;
  bool quizCompleted = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 60; // secondes par question
  Timer? timer;
  int? selectedAnswerIndex;
  bool answerSubmitted = false;
  List<UserQuizAnswer> userAnswers = [];
  DateTime? quizStartTime;

  // Animation
  late AnimationController _progressController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadQuizData();
  }

  @override
  void dispose() {
    timer?.cancel();
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
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
          
          // Sélectionner le premier module par défaut
          if (availableModules.isNotEmpty) {
            selectedModule = availableModules.first;
          }
        });

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

  /// Démarre le quiz avec le module sélectionné
  void startQuiz() {
    if (selectedModule == null || selectedModule!.questions.isEmpty) {
      _showError('Aucun module sélectionné ou module vide');
      return;
    }

    setState(() {
      quizStarted = true;
      currentQuestionIndex = 0;
      score = 0;
      quizCompleted = false;
      userAnswers.clear();
      quizStartTime = DateTime.now();
    });


    _startTimer();
  }

  void _startTimer() {
    final currentQuestion = selectedModule!.questions[currentQuestionIndex];
    timeLeft = currentQuestion.timeLimitSeconds;
    
    _progressController.duration = Duration(seconds: timeLeft);
    _progressController.reset();
    _progressController.forward();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _submitAnswer(null); // Temps écoulé
          }
        });
      }
    });
  }

  void _submitAnswer(int? answerIndex) {
    if (answerSubmitted) return;

    timer?.cancel();
    final currentQuestion = selectedModule!.questions[currentQuestionIndex];
    
    setState(() {
      selectedAnswerIndex = answerIndex;
      answerSubmitted = true;
    });

    // Calculer si la réponse est correcte
    final isCorrect = answerIndex == currentQuestion.correctOption;
    if (isCorrect) {
      score++;
    }

    // Enregistrer la réponse de l'utilisateur
    final userAnswer = UserQuizAnswer(
      questionId: currentQuestion.id,
      selectedOption: answerIndex ?? -1,
      isCorrect: isCorrect,
      pointsEarned: isCorrect ? currentQuestion.points : 0,
      answeredAt: DateTime.now(),
    );
    userAnswers.add(userAnswer);

    // Attendre 2 secondes avant la question suivante
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < selectedModule!.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        answerSubmitted = false;
      });
      _startTimer();
    } else {
      _endQuiz();
    }
  }

  void _endQuiz() {
    timer?.cancel();
    
    final totalTime = quizStartTime != null 
        ? DateTime.now().difference(quizStartTime!) 
        : Duration.zero;
    
    final quizResult = QuizResult(
      moduleId: selectedModule!.id,
      moduleTitle: selectedModule!.title,
      answers: userAnswers,
      totalQuestions: selectedModule!.questions.length,
      correctAnswers: score,
      totalPoints: selectedModule!.metadata.totalPoints,
      earnedPoints: userAnswers.fold(0, (sum, answer) => sum + answer.pointsEarned),
      totalTime: totalTime,
      percentage: (score / selectedModule!.questions.length) * 100,
    );
    
    setState(() {
      quizCompleted = true;
    });


    
    // Optionnel : soumettre les résultats à l'API
    _submitQuizResults(quizResult);
  }

  Future<void> _submitQuizResults(QuizResult result) async {
    try {
      final submitResult = await QuizApiService.submitQuizAnswers(
        moduleId: result.moduleId,
        answers: result.answers,
      );
      
      if (submitResult['success'] == true) {

      } else {

      }
    } catch (e) {

    }
  }

  void _showError(String message) {
    ErrorPopup.show(
      context,
      title: 'Erreur',
      message: message,
    );
  }

  void _resetQuiz() {
    setState(() {
      quizStarted = false;
      quizCompleted = false;
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswerIndex = null;
      answerSubmitted = false;
      userAnswers.clear();
    });
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoadingData) {
      return _buildLoadingView(theme);
    }
    
    if (hasError) {
      return _buildErrorView(theme);
    }
    
    if (quizStarted && !quizCompleted) {
      return _buildQuizView(theme);
    }
    
    if (quizCompleted) {
      return _buildResultsView(theme);
    }
    
    return _buildConfigurationView(theme);
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des modules de quiz...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
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
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuizData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationView(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Text(
                'Quiz ENA',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Testez vos connaissances avec nos modules de quiz',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Sélection du module
              _buildModuleSelection(theme),
              const SizedBox(height: 32),

              // Informations du module sélectionné
              if (selectedModule != null) ...[
                _buildModuleInfo(theme),
                const SizedBox(height: 32),
              ],

              // Bouton de démarrage
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedModule != null ? startQuiz : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Commencer le Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleSelection(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner un module',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtrage par niveau
            Text(
              'Niveau de difficulté',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['debutant', 'moyen', 'avance'].map((level) {
                final isSelected = selectedLevel == level;
                return FilterChip(
                  label: Text(_getLevelDisplayName(level)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedLevel = level;
                      _filterModulesByLevel();
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des modules filtrés
            Text(
              'Modules disponibles',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            
            ...availableModules.where((module) => 
              module.level == selectedLevel
            ).map((module) => _buildModuleTile(module, theme)).toList(),
            
            if (availableModules.where((m) => m.level == selectedLevel).isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucun module disponible pour ce niveau',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(QuizModule module, ThemeData theme) {
    final isSelected = selectedModule?.id == module.id;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        title: Text(
          module.title,
          style: GoogleFonts.poppins(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(module.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.quiz, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('${module.questions.length} questions'),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('${module.durationMinutes} min'),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('${module.metadata.totalPoints} pts'),
              ],
            ),
          ],
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
        onTap: () {
          setState(() {
            selectedModule = module;
          });
        },
      ),
    );
  }

  Widget _buildModuleInfo(ThemeData theme) {
    final module = selectedModule!;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              module.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(Icons.quiz, '${module.questions.length}', 'Questions', theme),
                _buildStatItem(Icons.timer, '${module.durationMinutes}', 'Minutes', theme),
                _buildStatItem(Icons.star, '${module.metadata.totalPoints}', 'Points', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _filterModulesByLevel() {
    // Cette méthode est appelée quand on change de niveau
    // Réinitialiser le module sélectionné si nécessaire
    if (selectedModule != null && selectedModule!.level != selectedLevel) {
      final filteredModules = availableModules.where((m) => m.level == selectedLevel).toList();
      selectedModule = filteredModules.isNotEmpty ? filteredModules.first : null;
    }
  }

  String _getLevelDisplayName(String level) {
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

  // Les méthodes _buildQuizView et _buildResultsView seront ajoutées dans la partie suivante...
  Widget _buildQuizView(ThemeData theme) {
    final currentQuestion = selectedModule!.questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / selectedModule!.questions.length;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress et timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}/${selectedModule!.questions.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: timeLeft <= 10 ? Colors.red : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$timeLeft s',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Barre de progression
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              const SizedBox(height: 32),
              
              // Question
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.question,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Options
                      ...currentQuestion.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return _buildOptionButton(index, option, currentQuestion, theme);
                      }).toList(),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Explication (si réponse soumise)
              if (answerSubmitted && currentQuestion.explanation.isNotEmpty) ...[
                Card(
                  color: selectedAnswerIndex == currentQuestion.correctOption 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selectedAnswerIndex == currentQuestion.correctOption 
                                  ? Icons.check_circle 
                                  : Icons.cancel,
                              color: selectedAnswerIndex == currentQuestion.correctOption 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedAnswerIndex == currentQuestion.correctOption 
                                  ? 'Correct !' 
                                  : 'Incorrect',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: selectedAnswerIndex == currentQuestion.correctOption 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentQuestion.explanation,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, String option, QuizQuestion question, ThemeData theme) {
    Color? backgroundColor;
    Color? textColor;
    IconData? icon;
    
    if (answerSubmitted) {
      if (index == question.correctOption) {
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check;
      } else if (index == selectedAnswerIndex) {
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.close;
      }
    } else if (selectedAnswerIndex == index) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.2);
      textColor = theme.colorScheme.primary;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: answerSubmitted ? null : () => _submitAnswer(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: backgroundColor != null 
                    ? Colors.transparent 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backgroundColor ?? Colors.transparent,
                    border: Border.all(
                      color: backgroundColor != null 
                          ? Colors.transparent 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  child: icon != null 
                      ? Icon(icon, size: 16, color: textColor)
                      : Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor ?? theme.colorScheme.onSurface,
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
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    final module = selectedModule!;
    final percentage = (score / module.questions.length) * 100;
    final earnedPoints = userAnswers.fold(0, (sum, answer) => sum + answer.pointsEarned);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Icône de résultat
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: percentage >= 70 ? Colors.green : Colors.orange,
                        ),
                        child: Icon(
                          percentage >= 70 ? Icons.check : Icons.star,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Quiz Terminé !',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        module.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Statistiques
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildResultStat('Score', '$score/${module.questions.length}', theme),
                                  _buildResultStat('Pourcentage', '${percentage.toStringAsFixed(1)}%', theme),
                                  _buildResultStat('Points', '$earnedPoints/${module.metadata.totalPoints}', theme),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage >= 70 ? Colors.green : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getGrade(percentage),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: percentage >= 70 ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Détail des réponses
                      Text(
                        'Détail des réponses',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ...userAnswers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final answer = entry.value;
                        final question = module.questions[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: answer.isCorrect 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : Colors.red.withValues(alpha: 0.1),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: answer.isCorrect ? Colors.green : Colors.red,
                              child: Icon(
                                answer.isCorrect ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Question ${index + 1}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              question.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${answer.pointsEarned}/${question.points} pts',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: answer.isCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetQuiz,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Nouveau Quiz',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Retour au menu principal
                        _resetQuiz();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Menu Principal',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Très bien';
    if (percentage >= 70) return 'Bien';
    if (percentage >= 60) return 'Assez bien';
    return 'Insuffisant';
  }
}
