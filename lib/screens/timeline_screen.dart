import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/personas.dart';
import '../models/post.dart';
import '../models/response.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/project_provider.dart';

/// タイムライン画面
class TimelineScreen extends ConsumerStatefulWidget {
  final String projectId;

  const TimelineScreen({super.key, required this.projectId});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<AiResponse> _generatedResponses = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
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
          .createPost(user.uid, widget.projectId, content);

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
          .saveResponses(user.uid, widget.projectId, postId, responses);

      // 最終活動日時を更新
      await ref
          .read(projectRepositoryProvider)
          .updateLastActivity(user.uid, widget.projectId);

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
    final postsAsync = ref.watch(postsStreamProvider(widget.projectId));

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/projects'),
        ),
        title: const Text(
          'タイムライン',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 投稿入力エリア
          _PostInputArea(
            controller: _textController,
            isGenerating: _isGenerating,
            onSubmit: _submitPost,
          ),

          const Divider(color: Colors.white10, height: 1),

          // タイムライン
          Expanded(
            child:
                _isGenerating
                    ? _LoadingState()
                    : _generatedResponses.isNotEmpty
                    ? _ResponseList(responses: _generatedResponses)
                    : postsAsync.when(
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purple,
                            ),
                          ),
                      error:
                          (e, _) => Center(
                            child: Text(
                              'エラー: $e',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      data:
                          (posts) =>
                              posts.isEmpty
                                  ? _EmptyTimeline()
                                  : _PostsList(
                                    posts: posts,
                                    projectId: widget.projectId,
                                  ),
                    ),
          ),
        ],
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'アイデアを投稿...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
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
                'AIペルソナが反応しています...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1500.ms, color: Colors.purple.withOpacity(0.3)),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'まだ投稿がありません',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'アイデアを投稿してAIからフィードバックを受けましょう',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
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
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color:
                  isQuote
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
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
                      color: sentimentColor.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      response.isRetweeted ? Icons.repeat_on : Icons.repeat,
                      color:
                          response.isRetweeted
                              ? Colors.green
                              : Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () {
                      // TODO: リツイート機能
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                response.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
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

class _PostsList extends ConsumerWidget {
  final List<Post> posts;
  final String projectId;

  const _PostsList({required this.posts, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final responsesAsync = ref.watch(
          responsesStreamProvider((projectId: projectId, postId: post.id)),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー投稿
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.2),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'あなた',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(post.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // レスポンス一覧
            responsesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data:
                  (responses) => Column(
                    children:
                        responses
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  left: 24,
                                ),
                                child: _ResponseCard(
                                  response: entry.value,
                                  index: entry.key,
                                ),
                              ),
                            )
                            .toList(),
                  ),
            ),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
