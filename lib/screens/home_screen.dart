import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/personas.dart';
import '../models/response.dart';
import '../models/response.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/project_provider.dart';

/// デフォルトプロジェクトIDプロバイダー
final defaultProjectIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final projectRepo = ref.read(projectRepositoryProvider);
  final firestore = ref.read(firestoreProvider);

  // 既存のプロジェクトを確認
  final snapshot =
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .limit(1)
          .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  }

  // なければデフォルトプロジェクト作成
  return await projectRepo.createProject(user.uid, 'アイデアノート');
});

/// ホーム画面（直接タイムライン）
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  List<AiResponse> _generatedResponses = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(String projectId) async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _generatedResponses = [];
    });

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // 投稿を保存
      final postId = await ref
          .read(postRepositoryProvider)
          .createPost(user.uid, projectId, content);

      // ペルソナを選抜してAI生成
      final personas = selectRandomPersonas(10);
      final aiService = ref.read(aiServiceProvider);
      final responses = await aiService.generateResponses(
        userContent: content,
        personas: personas,
      );

      // レスポンスを保存
      await ref
          .read(postRepositoryProvider)
          .saveResponses(user.uid, projectId, postId, responses);

      setState(() {
        _generatedResponses = responses;
      });

      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectIdAsync = ref.watch(defaultProjectIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thinker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: projectIdAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'エラー: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        data: (projectId) {
          if (projectId == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }
          return Column(
            children: [
              // 投稿入力エリア
              _PostInputArea(
                controller: _textController,
                isGenerating: _isGenerating,
                onSubmit: () => _submitPost(projectId),
              ),

              const Divider(color: Colors.white10, height: 1),

              // レスポンス表示
              Expanded(
                child:
                    _isGenerating
                        ? _LoadingState()
                        : _generatedResponses.isNotEmpty
                        ? _ResponseList(responses: _generatedResponses)
                        : _EmptyState(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback onSubmit;

  const _PostInputArea({
    required this.controller,
    required this.isGenerating,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 アイデアを投稿してAIからフィードバックを受けよう',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '新しいアイデアや考えを入力...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: isGenerating ? null : onSubmit,
                  icon:
                      isGenerating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            '10人のAIペルソナが\nあなたのアイデアにフィードバックします',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _PersonaChip('👩‍💼 辛口投資家'),
              _PersonaChip('👨‍🔬 データサイエンティスト'),
              _PersonaChip('👵 優しいおばあちゃん'),
              _PersonaChip('🎨 アーティスト'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _PersonaChip extends StatelessWidget {
  final String label;
  const _PersonaChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(height: 24),
              Text(
                '10人のAIペルソナが反応しています...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1500.ms,
            color: Colors.purple.withValues(alpha: 0.3),
          ),
    );
  }
}

class _ResponseList extends StatelessWidget {
  final List<AiResponse> responses;

  const _ResponseList({required this.responses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        final response = responses[index];
        return _ResponseCard(response: response, index: index);
      },
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final AiResponse response;
  final int index;

  const _ResponseCard({required this.response, required this.index});

  @override
  Widget build(BuildContext context) {
    final isQuote = response.type == ResponseType.quote;
    final sentimentColor = _getSentimentColor(response.sentiment);

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color:
                  isQuote
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
              width: isQuote ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sentimentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSentimentIcon(response.sentiment),
                      color: sentimentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response.personaName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          isQuote ? '引用' : '返信',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                response.content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          delay: Duration(milliseconds: index * 80),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(delay: Duration(milliseconds: index * 80), duration: 400.ms);
  }

  Color _getSentimentColor(Sentiment sentiment) {
    switch (sentiment) {
      case Sentiment.positive:
        return Colors.green;
      case Sentiment.negative:
        return Colors.orange;
      case Sentiment.neutral:
        return Colors.blue;
    }
  }

  IconData _getSentimentIcon(Sentiment sentiment) {
    switch (sentiment) {
      case Sentiment.positive:
        return Icons.thumb_up;
      case Sentiment.negative:
        return Icons.thumb_down;
      case Sentiment.neutral:
        return Icons.analytics;
    }
  }
}
