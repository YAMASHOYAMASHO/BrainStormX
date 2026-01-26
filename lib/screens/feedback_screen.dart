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

  // Comment input
  final TextEditingController _commentController = TextEditingController();
  String? _currentCommentContext; // The user comment that triggered current AI generation

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

  Future<void> _startAiGeneration({String? userComment}) async {
    // Start text animation immediately
    _matchTextAnimation();

    // Clear previous ephemeral feedback items
    setState(() {
      _feedbackItems.clear();
    });

    try {
      // 1. Select Personas
      final personas = ref.read(selectedPersonasProvider);

      // 2. Build context from thread history if this is a comment
      String? context;
      if (userComment != null) {
        _currentCommentContext = userComment;
        final ideas = ref.read(ideaRepositoryProvider);
        final thread = ideas.firstWhere(
          (i) => i.id == _ideaId,
          orElse: () => IdeaThread(id: '', title: '', createdAt: DateTime.now()),
        );

        // Build context from pinned items (previous conversation)
        if (thread.pinnedItems.isNotEmpty) {
          final historyItems = thread.pinnedItems.map((item) {
            final prefix = item.isUserComment ? '【ユーザーの追加コメント】' : '【${item.authorName}の意見】';
            return '$prefix ${item.content}';
          }).join('\n');
          context = '$historyItems\n\n【ユーザーの新しいコメント】\n$userComment';
        } else {
          context = '【ユーザーの新しいコメント】\n$userComment';
        }
      }

      // 3. Call AI Stream
      final stream = ref.read(aiServiceProvider).generateResponsesStream(
        userContent: _ideaTitle,
        personas: personas,
        context: context,
      );

      // 4. Consume Stream
      await for (final item in stream) {
        if (!mounted) break;

        setState(() {
          _feedbackItems.add(item);
        });

        // "Buffer" effect: Wait for 3 items before showing the list
        if (_feedbackItems.length == 3 && _isAnimating) {
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

  // Submit a user comment and trigger AI feedback
  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    // 1. Save user comment to thread
    await ref.read(ideaRepositoryProvider.notifier).addUserComment(_ideaId, comment);

    // 2. Clear input
    _commentController.clear();

    // 3. Start AI generation with the comment as context
    setState(() {
      _isAnimating = true;
      _hasStarted = true;
    });
    _startAiGeneration(userComment: comment);
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
    _commentController.dispose();
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
      // Comment input bar (shown when thread has started)
      bottomNavigationBar: _hasStarted && !_isAnimating ? _buildCommentInput() : null,
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'コメントを追加...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _submitComment,
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF4A4A4A),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE5E5EA),
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
    final ideas = ref.watch(ideaRepositoryProvider);
    final existingThread = ideas.firstWhere(
      (i) => i.id == _ideaId,
      orElse: () => IdeaThread(id: '', title: '', createdAt: DateTime.now()),
    );

    // Show pinned items first, then ephemeral feedback items
    final pinnedItems = existingThread.pinnedItems;
    final bool hasEphemeralItems = _feedbackItems.isNotEmpty;

    // Calculate total items: Header + Pinned + (Ephemeral or "Get More" button)
    final int headerCount = 1;
    final int pinnedCount = pinnedItems.length;
    final int ephemeralCount = hasEphemeralItems ? _feedbackItems.length : 0;
    final int moreButtonCount = (pinnedItems.isNotEmpty && !hasEphemeralItems) ? 1 : 0;
    final int totalCount = headerCount + pinnedCount + ephemeralCount + moreButtonCount;

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
      itemCount: totalCount,
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

        // Pinned items section
        if (index <= pinnedCount) {
          final pinnedIndex = index - 1;
          final item = pinnedItems[pinnedIndex];

          // User comment - distinct style
          if (item.isUserComment) {
            return _buildUserCommentItem(item);
          }

          // AI feedback from pinned items
          return _buildFeedbackItem(
            content: item.content,
            authorName: item.authorName,
            isPinned: true,
          );
        }

        // "Get More Opinions" button (shown when no ephemeral items)
        if (!hasEphemeralItems && index == pinnedCount + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isAnimating = true;
                    _hasStarted = true;
                  });
                  _startAiGeneration();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("さらに意見を求める"),
              ),
            ),
          );
        }

        // Ephemeral feedback items (newly generated)
        final ephemeralIndex = index - pinnedCount - 1;
        if (ephemeralIndex >= 0 && ephemeralIndex < _feedbackItems.length) {
          final item = _feedbackItems[ephemeralIndex];
          return _buildFeedbackItem(
            content: item.content,
            authorName: item.personaName,
            personaId: item.personaId,
            isPinned: false,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUserCommentItem(ThreadItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 48), // Offset to align with AI feedback
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'あなたのコメント',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, duration: 400.ms);
  }

  Widget _buildFeedbackItem({
    required String content,
    required String authorName,
    String? personaId,
    required bool isPinned,
  }) {
    // Find persona details
    late Persona persona;
    String pId = personaId ?? '';

    try {
      if (pId.isNotEmpty) {
        persona = defaultPersonas.firstWhere((p) => p.id == pId);
      } else {
        persona = defaultPersonas.firstWhere((p) => p.name == authorName);
        pId = persona.id;
      }
    } catch (e) {
      persona = defaultPersonas.first;
      pId = persona.id;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona Icon (Clickable)
          GestureDetector(
            onTap: () => _showBio(
              context,
              AiResponse(
                id: '',
                personaId: pId,
                personaName: authorName,
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
                backgroundColor: _getCategoryColor(persona.category).withValues(alpha: 0.1),
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
                context.push(
                  '/feedback/detail',
                  extra: {
                    'ideaData': widget.ideaData,
                    'content': content,
                    'personaId': pId,
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Persona Name
                  GestureDetector(
                    onTap: () => _showBio(
                      context,
                      AiResponse(
                        id: '',
                        personaId: pId,
                        personaName: authorName,
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

          // Checkmark Action (only for non-pinned items)
          if (!isPinned)
            IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFB0B0B0),
                size: 20,
              ),
              onPressed: () {
                ref
                    .read(ideaRepositoryProvider.notifier)
                    .pinItem(_ideaId, content, persona.name);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('メインスレッドに刻みました'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            )
          else
            const SizedBox(width: 48), // Placeholder for alignment
        ],
      ),
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
