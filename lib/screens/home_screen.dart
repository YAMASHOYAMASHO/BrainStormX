import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/idea_repository_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _ideaController = TextEditingController();

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  void _submitIdea() async {
    if (_ideaController.text.isNotEmpty) {
      final title = _ideaController.text;
      _ideaController.clear();

      // Create new idea in repository
      final ideaId = await ref
          .read(ideaRepositoryProvider.notifier)
          .createIdea(title);

      if (mounted) {
        context.push('/feedback', extra: {'id': ideaId, 'title': title});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Marble White
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Header
              Text(
                'SCLUP',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4A4A), // Dark Stone Grey
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'アイデアを彫る。考えを刻む。',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF8E8E93), // Muted Grey
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2), // Minimalist
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _ideaController,
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(color: Color(0xFF333333)), // Dark Text
                  decoration: InputDecoration(
                    hintText: '今日はどんなアイデアを刻みますか？',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A), // Dark Stone
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '刻む',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Past Threads Header
              Text(
                'ギャラリー',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF636366),
                ),
              ),
              const SizedBox(height: 20),

              // Main Thread Gallery from Provider
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final ideas = ref.watch(ideaRepositoryProvider);

                    if (ideas.isEmpty) {
                      return Center(
                        child: Text(
                          "まだ彫刻はありません",
                          style: GoogleFonts.lato(
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideas[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to view existing thread (Reuse FeedbackScreen or new one?)
                            // For now reusing FeedbackScreen but maybe we need a mode?
                            // Let's pass the ID so FeedbackScreen can load it.
                            context.push(
                              '/feedback',
                              extra: {'id': idea.id, 'title': idea.title},
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  idea.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSerifJp(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "${idea.createdAt.month}/${idea.createdAt.day} ${idea.createdAt.hour}:${idea.createdAt.minute.toString().padLeft(2, '0')}",
                                      style: GoogleFonts.lato(
                                        color: const Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.format_quote,
                                      size: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${idea.pinnedItems.length}",
                                      style: GoogleFonts.lato(
                                        color: const Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
