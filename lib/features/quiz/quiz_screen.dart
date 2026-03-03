import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'providers/quiz_provider.dart';
import '../../core/utils.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String colorHex;

  const QuizScreen({
    super.key,
    required this.subjectId,
    required this.colorHex,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;
  bool _configDone = false;

  // Timer state
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) return;
    setState(() => _timeLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        timer.cancel();
        ref.read(quizProvider(widget.subjectId).notifier).timeOut();
      }
    });
  }

  Future<bool> _onWillPop() async {
    final quizState = ref.read(quizProvider(widget.subjectId)).valueOrNull;
    if (quizState == null || quizState.isFinished || !_configDone) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      _timer?.cancel();
      ref.read(quizProvider(widget.subjectId).notifier).endQuizEarly();
    }

    return shouldLeave ?? false;
  }

  void _showConfigSheet(BuildContext context, Color color, int totalQuestions) {
    final config = ref.read(quizConfigProvider);
    var selectedDifficulty = config.difficulty;
    var selectedSpeed = config.speed;
    int? selectedLimit = config.questionLimit;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Game Setup',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Question count
                  Text('Questions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final count in [5, 10, 15, null])
                        ChoiceChip(
                          label: Text(count == null
                              ? 'All ($totalQuestions)'
                              : '$count'),
                          selected: selectedLimit == count,
                          selectedColor: color.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              setModalState(() => selectedLimit = count),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Difficulty
                  Text('Difficulty',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _ModeChip(
                        label: 'Plot Armor',
                        emoji: '🛡️',
                        subtitle: 'Unlimited',
                        selected: selectedDifficulty == Difficulty.plotArmor,
                        color: Colors.green,
                        onTap: () => setModalState(
                            () => selectedDifficulty = Difficulty.plotArmor),
                      ),
                      _ModeChip(
                        label: 'Almost Him',
                        emoji: '💔',
                        subtitle: '3 lives',
                        selected: selectedDifficulty == Difficulty.almostHim,
                        color: Colors.orange,
                        onTap: () => setModalState(
                            () => selectedDifficulty = Difficulty.almostHim),
                      ),
                      _ModeChip(
                        label: 'Canon Event',
                        emoji: '💀',
                        subtitle: 'No mercy',
                        selected: selectedDifficulty == Difficulty.canonEvent,
                        color: Colors.red,
                        onTap: () => setModalState(
                            () => selectedDifficulty = Difficulty.canonEvent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Speed
                  Text('Speed',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _ModeChip(
                        label: 'Snail Mode',
                        emoji: '🐌',
                        subtitle: 'No timer',
                        selected: selectedSpeed == Speed.snail,
                        color: Colors.blue,
                        onTap: () =>
                            setModalState(() => selectedSpeed = Speed.snail),
                      ),
                      _ModeChip(
                        label: 'Crunch Time',
                        emoji: '⏱️',
                        subtitle: '15s',
                        selected: selectedSpeed == Speed.crunchTime,
                        color: Colors.amber,
                        onTap: () => setModalState(
                            () => selectedSpeed = Speed.crunchTime),
                      ),
                      _ModeChip(
                        label: 'Panic!',
                        emoji: '🔥',
                        subtitle: '7s',
                        selected: selectedSpeed == Speed.panic,
                        color: Colors.deepOrange,
                        onTap: () =>
                            setModalState(() => selectedSpeed = Speed.panic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  FilledButton(
                    onPressed: () {
                      ref.read(quizConfigProvider.notifier).state = QuizConfig(
                        questionLimit: selectedLimit,
                        difficulty: selectedDifficulty,
                        speed: selectedSpeed,
                      );
                      Navigator.pop(ctx);
                      setState(() => _configDone = true);
                      // Force reload with new config
                      ref.invalidate(quizProvider(widget.subjectId));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Start Quiz',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizStateAsync = ref.watch(quizProvider(widget.subjectId));
    final color = safeParseColor(widget.colorHex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: color),
          actions: [
            if (_configDone)
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  ref
                      .read(quizProvider(widget.subjectId).notifier)
                      .endQuizEarly();
                },
                child: Text('Quit',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        body: Stack(
          children: [
            quizStateAsync.when(
              data: (quizState) {
                // Show config sheet on first load
                if (!_configDone && quizState.questions.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_configDone) {
                      _showConfigSheet(
                          context, color, quizState.questions.length);
                    }
                  });
                  return Center(child: CircularProgressIndicator(color: color));
                }

                if (quizState.questions.isEmpty) {
                  return const Center(
                      child: Text('No questions available for this subject.'));
                }

                if (quizState.isFinished) {
                  _timer?.cancel();
                  final accuracy =
                      (quizState.score / quizState.questions.length) * 100;
                  if (accuracy >= 60 &&
                      !_hasPlayedConfetti &&
                      !quizState.isGameOver) {
                    _hasPlayedConfetti = true;
                    _confettiController.play();
                  }
                  return _buildResultScreen(context, ref, quizState, color);
                }

                // Start timer for timed modes (guard: only if not finished)
                final timePerQ = quizState.config.timePerQuestion;
                if (timePerQ > 0 && _timeLeft <= 0 && !quizState.isFinished) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!quizState.isFinished) {
                      _startTimer(timePerQ);
                    }
                  });
                }

                final currentQuestion =
                    quizState.questions[quizState.currentIndex];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar: question counter + lives
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${quizState.currentIndex + 1} of ${quizState.questions.length}',
                            style: TextStyle(
                                fontSize: 16,
                                color: color.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700),
                          ),
                          if (quizState.config.difficulty !=
                              Difficulty.plotArmor)
                            Row(
                              children:
                                  List.generate(quizState.config.maxLives, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Icon(
                                    i < quizState.livesRemaining
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (quizState.currentIndex + 1) /
                              quizState.questions.length,
                          minHeight: 8,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.15),
                        ),
                      ),

                      // Timer bar
                      if (timePerQ > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _timeLeft / timePerQ,
                            minHeight: 6,
                            color: _timeLeft <= 3 ? Colors.red : Colors.amber,
                            backgroundColor:
                                Colors.amber.withValues(alpha: 0.15),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    _timeLeft <= 3 ? Colors.red : Colors.amber,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      Text(
                        currentQuestion.text,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.3),
                      ),
                      const SizedBox(height: 40),
                      ...List.generate(currentQuestion.options.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 24),
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              elevation: 0,
                              alignment: Alignment.centerLeft,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: color.withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                            ),
                            onPressed: () {
                              _timer?.cancel();
                              ref
                                  .read(quizProvider(widget.subjectId).notifier)
                                  .answerQuestion(index);
                              // Restart timer for next question
                              if (timePerQ > 0) {
                                _startTimer(timePerQ);
                              }
                            },
                            child: Text(
                              currentQuestion.options[index],
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () =>
                  Center(child: CircularProgressIndicator(color: color)),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 1,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(
      BuildContext context, WidgetRef ref, QuizState state, Color color) {
    final accuracy = (state.score / state.questions.length) * 100;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isGameOver
                  ? Icons.heart_broken
                  : (accuracy >= 60 ? Icons.emoji_events : Icons.refresh),
              size: 80,
              color: state.isGameOver ? Colors.red : color,
            ),
            const SizedBox(height: 16),
            Text(
              state.isGameOver ? 'Game Over!' : 'Quiz Completed!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${state.score} / ${state.questions.length}',
              style: const TextStyle(fontSize: 22),
            ),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (state.isGameOver) ...[
              const SizedBox(height: 8),
              Text('Lives depleted 💔',
                  style: TextStyle(fontSize: 14, color: Colors.red.shade300)),
            ],
            const SizedBox(height: 32),
            if (state.missedQuestionIds.isNotEmpty) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Review Mistakes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  setState(() => _hasPlayedConfetti = false);
                  ref
                      .read(quizProvider(widget.subjectId).notifier)
                      .restartWithMistakes();
                },
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Mode Chip Widget ──

class _ModeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                )),
            Text(subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: selected
                      ? color.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
