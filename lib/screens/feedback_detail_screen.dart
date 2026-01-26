import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/idea_repository_provider.dart';

import '../providers/ai_provider.dart';
import '../data/personas.dart'; // For finding the persona

class FeedbackDetailScreen extends ConsumerStatefulWidget {
  final String originalFeedback;
  final Map<String, dynamic> ideaData; // ID, Title needed for pinning
  final String? personaId; // Nullable for compatibility, but should be passed

  const FeedbackDetailScreen({
    super.key,
    required this.originalFeedback,
    required this.ideaData,
    this.personaId,
  });

  @override
  ConsumerState<FeedbackDetailScreen> createState() =>
      _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends ConsumerState<FeedbackDetailScreen> {
  final List<String> _responses = [];
  bool _isGenerating = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    // 1. Find Persona
    final personaId = widget.personaId;
    if (personaId == null) {
      if (mounted) setState(() => _isGenerating = false);
      return;
    }

    final persona = defaultPersonas.firstWhere(
      (p) => p.id == personaId,
      orElse: () => defaultPersonas.first,
    );

    try {
      final stream = ref
          .read(aiServiceProvider)
          .generateDeepCarvingStream(
            userContent: widget.ideaData['title'] ?? '',
            originalFeedback: widget.originalFeedback,
            persona: persona,
          );

      await for (final content in stream) {
        if (!mounted) break;
        setState(() {
          _responses.add(content);
        });
      }

      if (mounted) setState(() => _isGenerating = false);
    } catch (e) {
      debugPrint("AI Error: $e");
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Marble White
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF4A4A4A)),
        title: Text(
          '深彫り',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF4A4A4A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF4A4A4A)),
            onPressed: () {
              ref
                  .read(ideaRepositoryProvider.notifier)
                  .pinItem(
                    widget.ideaData['id'],
                    widget.originalFeedback,
                    "Original",
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('元の意見をメインスレッドに刻みました')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Original Feedback (Header)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              widget.originalFeedback,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF333333),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Streaming Responses
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _responses.length + (_isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _responses.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Colors.grey.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final response = _responses[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 16, top: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              response,
                              style: const TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Action Row (Add to main thread)
                            InkWell(
                              onTap: () {
                                ref
                                    .read(ideaRepositoryProvider.notifier)
                                    .pinItem(
                                      widget.ideaData['id'],
                                      response,
                                      "AI",
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('メインスレッドに刻みました'),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '記憶に刻む',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
