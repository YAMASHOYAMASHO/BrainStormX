import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/idea_repository_provider.dart';
import '../providers/ai_provider.dart';
import '../models/response.dart';
import '../models/persona.dart';
import '../data/personas.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> ideaData; // Expects {'id': '...', 'title': '...'}

  const FeedbackScreen({super.key, required this.ideaData});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final List<AiResponse> _feedbackItems = [];
  bool _isAnimating = false;
  bool _hasError = false;
  bool _hasStarted = false; // Track if we explicitly started generation

  String get _ideaId => widget.ideaData['id'];
  String get _ideaTitle => widget.ideaData['title'];

  // Text Animation State
  int _loadingTextIndex = 0;
  final List<String> _loadingTexts = [
    "思考中...",
    "視点を収集中...",
    "彫刻中...",
    "研磨中...",
  ];

  @override
  void initState() {
    super.initState();
    // Check if we have existing pinned items.
    // We need to delay this check slightly or do it in build/didChangeDependencies
    // effectively, or just rely on the repository provider since we have the ID.
    // But since this is initState, we can just check if we want to auto-start.
    // Actually, logic:
    // If accessing from Gallery, we want to SEE the thread.
    // If accessing from "New Idea", we want to START.
    // The router params don't distinguish, but we can check if the thread has items.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ideas = ref.read(ideaRepositoryProvider);
      final existingThread = ideas.firstWhere(
        (i) => i.id == _ideaId,
        orElse:
            () => IdeaThread(
              id: '',
              title: '',
              createdAt: DateTime.now(),
            ), // Dummy
      );

      if (existingThread.pinnedItems.isNotEmpty) {
        // Mode: View Existing
        setState(() {
          _isAnimating = false;
          _hasStarted = true; // Treated as "started" so we show content
          // We don't populate _feedbackItems here because we want to show PINNED items?
          // The USER said: "Show own idea only... and button" if nothing added.
          // If something added (pinnedItems), show them.
        });
      } else {
        // Mode: New or Empty
        // User requested: "If nothing added, only show idea and 'Get Feedback' button"
        // So we should NOT auto-start.
        setState(() {
          _isAnimating = false;
          _hasStarted = false;
        });
      }
    });
  }

  Future<void> _startAiGeneration() async {
    // Start text animation immediately
    _matchTextAnimation();

    try {
      // 1. Select Personas
      final personas = ref.read(selectedPersonasProvider);

      // 2. Call AI Stream
      final stream = ref
          .read(aiServiceProvider)
          .generateResponsesStream(userContent: _ideaTitle, personas: personas);

      // 3. Consume Stream
      await for (final item in stream) {
        if (!mounted) break;

        setState(() {
          _feedbackItems.add(item);
        });

        // "Buffer" effect: Wait for 3 items before showing the list
        if (_feedbackItems.length == 3 && _isAnimating) {
          // Add a small delay for dramatic effect if needed, or switch immediately
          setState(() => _isAnimating = false);
        }
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isAnimating = false;
        });
      }
    }
  }

  void _matchTextAnimation() {
    // Text Animation Loop
    Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!_isAnimating && mounted) {
        timer.cancel();
      } else if (mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  // void _startStreaming() { // This method is no longer needed
  //   // Feedback Stream Loop
  //   int itemsCount = 0;
  //   _streamTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
  //     if (itemsCount < _generatedResponses.length) {
  //       setState(() {
  //         _feedbackItems.add(_generatedResponses[itemsCount]);
  //         itemsCount++;
  //       });

  //       // After 3 items, switch layout
  //       if (_feedbackItems.length >= 3 && _isAnimating) {
  //         Future.delayed(const Duration(seconds: 1), () {
  //           if (mounted) setState(() => _isAnimating = false);
  //         });
  //       }
  //     } else {
  //       timer.cancel();
  //     }
  //   });
  // }

  @override
  void dispose() {
    // _streamTimer?.cancel(); // No longer needed
    super.dispose();
  }

  void _showBio(BuildContext context, AiResponse item) {
    // Find the original persona object to get color/occupation
    final persona = defaultPersonas.firstWhere(
      (p) => p.id == item.personaId,
      orElse: () => defaultPersonas.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getCategoryColor(
                        persona.category,
                      ).withOpacity(0.2),
                      child: Text(
                        persona.name[0],
                        style: TextStyle(
                          color: _getCategoryColor(persona.category),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            persona.occupation,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "性格・特徴",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  persona.systemPrompt,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Color _getCategoryColor(dynamic category) {
    // Basic mapping, assuming category enum exists or string
    // You might need to adjust based on actual Enum in persona.dart
    if (category.toString().contains('positive')) return Colors.orange;
    if (category.toString().contains('negative')) return Colors.blueGrey;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        leading: BackButton(
          color: const Color(0xFF4A4A4A),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          _isAnimating ? '思考を収集中...' : '彫刻',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF4A4A4A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Content Layer
          if (_hasError)
            Center(
              child: Text(
                "AIの接続に失敗しました。\nもう一度お試しください。",
                textAlign: TextAlign.center,
              ),
            )
          else if (!_hasStarted)
            _buildStartButton()
          else if (!_isAnimating)
            _buildStreamingContent(),

          // Animation Layer
          IgnorePointer(
            ignoring: !_isAnimating,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _isAnimating ? 1.0 : 0.0,
              child: _buildTextAnimation(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _ideaTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifJp(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAnimating = true;
                _hasStarted = true;
              });
              _startAiGeneration();
            },
            icon: const Icon(Icons.psychology, color: Colors.white),
            label: const Text("意見を求める"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAnimation() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Central Text Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Text(
              _loadingTexts[_loadingTextIndex],
              key: ValueKey<int>(_loadingTextIndex),
              style: GoogleFonts.notoSerifJp(
                // Using Serif specifically
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4A4A),
                letterSpacing: 4.0,
              ),
            ),
          ),

          // Orbiting Shadows
          ...List.generate(6, (index) {
            final angle = (index * 60) * (3.14159 / 180);
            final radius = 140.0;
            return Positioned(
              left: (cos(angle) * radius) + 10,
              top: (sin(angle) * radius),
              child: _ShadowBubble(delay: index * 300),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStreamingContent() {
    // If we have pinned items (revisit), show them?
    // Actually the current implementation streams into _feedbackItems (ephemeral).
    // If revisiting, we probably want to see the PINNED items, OR the ephemeral ones if just generated.
    // The user said: "If nothing added... show button".
    // If pinned items exist, we should probably show them.
    // Let's merge: Show pinned items FIRST, then ephemeral items?
    // Or just switch data source.

    final ideas = ref.watch(ideaRepositoryProvider);
    final existingThread = ideas.firstWhere(
      (i) => i.id == _ideaId,
      orElse:
          () => IdeaThread(
            id: '',
            title: '',
            createdAt: DateTime.now(),
          ), // Should not happen
    );

    // Combine pinned and ephemeral?
    // Ephemeral items are `AiResponse`. Pinned items are `ThreadItem`.
    // We need a unified view or just decide what to show.
    // If _feedbackItems is active (just generated), show them.
    // If not, show pinnedItems.

    final bool showPinned =
        _feedbackItems.isEmpty && existingThread.pinnedItems.isNotEmpty;
    final int count =
        showPinned ? existingThread.pinnedItems.length : _feedbackItems.length;

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount:
          count +
          1 +
          (showPinned ? 1 : 0), // +1 for Header, +1 for "More" button if pinned
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header (Original Idea)
          return Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '題材',
                  style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _ideaTitle,
                  style: GoogleFonts.notoSerifJp(
                    // Japanese Serif
                    color: const Color(0xFF333333),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 40, color: Color(0xFFE5E5EA)),
              ],
            ),
          );
        }

        if (showPinned && index == count + 1) {
          // "Get More Opinions" button at bottom of pinned list
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isAnimating = true;
                    _hasStarted = true;
                    // Clear ephemeral just in case, or append?
                    // Let's just start generation, which adds to _feedbackItems
                  });
                  _startAiGeneration();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("さらに意見を求める"),
              ),
            ),
          );
        }

        // Data binding
        String content;
        String personaName = "Unknown";
        String personaId = ""; // Need this for bio
        Persona? persona;

        if (showPinned) {
          final item = existingThread.pinnedItems[index - 1];
          content = item.content;
          personaName =
              item.authorName; // We only stored name... uh oh. We need ID to show bio.
          // Problem: ThreadItem only saved authorName. We can't link back to Persona object easily unless we store ID.
          // Fallback: Try to find by name or just use a generic icon.
          try {
            persona = defaultPersonas.firstWhere((p) => p.name == personaName);
            personaId = persona.id;
          } catch (e) {
            // Fallback
            personaId = "";
          }
        } else {
          final item = _feedbackItems[index - 1];
          content = item.content;
          personaId = item.personaId;
          personaName = item.personaName;
        }

        // Find persona details (re-lookup if needed)
        if (persona == null && personaId.isNotEmpty) {
          persona = defaultPersonas.firstWhere(
            (p) => p.id == personaId,
            orElse: () => defaultPersonas.first,
          );
        } else if (persona == null) {
          // Absolute fallback
          persona = defaultPersonas.first;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Persona Icon (Clickable)
              GestureDetector(
                onTap:
                    () => _showBio(
                      context,
                      AiResponse(
                        // Hacky reconstruction for bio
                        id: '',
                        personaId: personaId,
                        personaName: personaName,
                        type: ResponseType.reply,
                        content: content,
                        sentiment: Sentiment.neutral,
                        isRetweeted: false,
                        createdAt: DateTime.now(),
                      ),
                    ),
                child: Container(
                  margin: const EdgeInsets.only(top: 4, right: 16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _getCategoryColor(
                      persona!.category,
                    ).withOpacity(0.1),
                    child: Text(
                      persona.name[0],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(persona.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Start drill down - we probably want to pass ID here too if we want to save drill-down items
                    // For now keeping it simple as per original scope (saving logic might need update in detail screen too)
                    // Let's pass the ID map to Detail Screen too
                    context.push(
                      '/feedback/detail',
                      extra: {
                        'ideaData': widget.ideaData,
                        'content': content,
                        'personaId': personaId,
                      },
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Persona Name
                      GestureDetector(
                        onTap:
                            () =>
                                showPinned || persona == null
                                    ? null
                                    : _showBio(
                                      context,
                                      AiResponse(
                                        // Hacky reconstruction for bio
                                        id: '',
                                        personaId: personaId,
                                        personaName: personaName,
                                        type: ResponseType.reply,
                                        content: content,
                                        sentiment: Sentiment.neutral,
                                        isRetweeted: false,
                                        createdAt: DateTime.now(),
                                      ),
                                    ),
                        child: Text(
                          persona.name,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: 0.1, duration: 400.ms),
              ),

              // Checkmark Action
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFFB0B0B0),
                  size: 20,
                ),
                selectedIcon: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4A4A4A),
                  size: 20,
                ),
                onPressed: () {
                  ref
                      .read(ideaRepositoryProvider.notifier)
                      .pinItem(_ideaId, content, persona!.name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('メインスレッドに刻みました'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShadowBubble extends StatelessWidget {
  final int delay;

  const _ShadowBubble({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
              bottomLeft: const Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.format_quote,
            size: 16,
            color: Colors.grey.shade400,
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 600.ms, delay: Duration(milliseconds: delay))
        .moveY(
          begin: 10,
          end: -10,
          duration: 2.seconds,
          curve: Curves.easeInOut,
        )
        .fadeOut(delay: 1500.ms, duration: 600.ms);
  }
}
