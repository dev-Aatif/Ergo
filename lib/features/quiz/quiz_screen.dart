import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'providers/quiz_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizStateAsync = ref.watch(quizProvider(widget.subjectId));
    final color = Color(int.parse(widget.colorHex.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: Stack(
        children: [
          quizStateAsync.when(
            data: (quizState) {
              if (quizState.questions.isEmpty) {
                return const Center(
                    child: Text('No questions available for this subject.'));
              }

              if (quizState.isFinished) {
                final accuracy =
                    (quizState.score / quizState.questions.length) * 100;
                if (accuracy >= 60 && !_hasPlayedConfetti) {
                  _hasPlayedConfetti = true;
                  _confettiController.play();
                }

                return _buildResultScreen(context, ref, quizState, color);
              }

              final currentQuestion =
                  quizState.questions[quizState.currentIndex];

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Question ${quizState.currentIndex + 1} of ${quizState.questions.length}',
                      style: TextStyle(
                          fontSize: 16,
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (quizState.currentIndex + 1) /
                            quizState.questions.length,
                        minHeight: 8,
                        color: color,
                        backgroundColor: color.withOpacity(0.15),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      currentQuestion.text,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.3),
                    ),
                    const SizedBox(height: 48),
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
                                  color: color.withOpacity(0.3), width: 1.5),
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(quizProvider(widget.subjectId).notifier)
                                .answerQuestion(index);
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
              blastDirection: pi / 2, // Straight down
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
            Icon(accuracy >= 60 ? Icons.emoji_events : Icons.refresh,
                size: 80, color: color),
            const SizedBox(height: 16),
            const Text(
              'Quiz Completed!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  setState(() {
                    _hasPlayedConfetti = false;
                  });
                  ref
                      .read(quizProvider(widget.subjectId).notifier)
                      .restartWithMistakes();
                },
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}
