import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/personas.dart';
import '../models/persona.dart';
import '../models/response.dart';

/// Firebase AI (Gemini) を使用したAIサービス
class AiService {
  late final GenerativeModel _model;

  AiService() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
  }

  /// ペルソナ達からのレスポンスを生成 (ストリーム版)
  Stream<AiResponse> generateResponsesStream({
    required String userContent,
    required List<Persona> personas,
    String? context,
  }) async* {
    final personaListText = personas
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key + 1;
          final p = entry.value;
          return '$i. {id: "${p.id}", name: "${p.name}", occupation: "${p.occupation}", tone: "${p.tone}", prompt: "${p.systemPrompt}"}';
        })
        .join('\n');

    final contextSection =
        context != null && context.isNotEmpty
            ? '\n\n【これまでの議論の文脈】\n$context'
            : '';

    final prompt = '''
あなたは仮想SNSのシミュレータです。以下のユーザーの投稿に対し、指定された複数のペルソナになりきってJSON形式で反応を出力してください。

【重要な制約】
- これはフィクションのブレインストーミング環境であり、批判的な意見も歓迎されます。
- 各ペルソナの口調と視点を厳密に守ること。
- 肯定的なペルソナは応援・賛同を、否定的なペルソナは批判・懸念を、分析的なペルソナは客観的な分析を行うこと。
- 出力は **JSON Lines形式（1行につき1つのJSONオブジェクト）** で出力してください。
- 配列の開始括弧 `[` や終了括弧 `]` 、カンマ `,` は **不要** です。改行で区切ってください。

【参加ペルソナリスト】
$personaListText

【ユーザー投稿】
$userContent$contextSection

【出力フォーマット】
以下のJSONオブジェクトを、ペルソナの数だけ改行区切りで出力:
{"personaId": "ペルソナID", "personaName": "表示名", "type": "REPLY", "content": "反応内容(50-150文字)", "sentiment": "POSITIVE/NEGATIVE/NEUTRAL"}
''';

    try {
      final contentStream = _model.generateContentStream(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType:
              'text/plain', // JSONL treated as text for cleaner stream
          temperature: 0.9,
        ),
      );

      // Stream handling setup
      int index = 0;
      final now = DateTime.now();

      // Transform the response stream to lines
      final lineStream = contentStream
          .map((response) => response.text ?? '')
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;

        // Skip potential array markers if the model ignores instructions
        if (cleanLine == '[' || cleanLine == ']') continue;

        try {
          // Remove trailing comma if present (common mistake by models)
          final jsonStr =
              cleanLine.endsWith(',')
                  ? cleanLine.substring(0, cleanLine.length - 1)
                  : cleanLine;

          final json = jsonDecode(jsonStr) as Map<String, dynamic>;

          yield AiResponse(
            id: 'temp_${now.millisecondsSinceEpoch}_$index',
            personaId: json['personaId'] ?? '',
            personaName: json['personaName'] ?? '',
            type:
                (json['type'] ?? 'REPLY').toString().toUpperCase() == 'QUOTE'
                    ? ResponseType.quote
                    : ResponseType.reply,
            content: json['content'] ?? '',
            sentiment: _parseSentiment(json['sentiment']),
            isRetweeted: false,
            createdAt: now.add(Duration(milliseconds: index * 500)),
          );
          index++;
        } catch (e) {
          // Ignore parsing errors for individual lines (e.g. partial lines)
          // In a production app, we might want to buffer partial chunks manually if LineSplitter isn't enough,
          // but for Gemini text output, it usually outputs line by line efficiently.
          continue;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 「深彫り」分析を生成 (ストリーム版)
  /// 特定のペルソナが、自身の発言をさらに掘り下げる
  Stream<String> generateDeepCarvingStream({
    required String userContent,
    required String originalFeedback,
    required Persona persona,
  }) async* {
    final prompt = '''
あなたは${persona.name}（${persona.occupation}）です。
口調：${persona.tone}
性格：${persona.systemPrompt}

【ユーザーのアイデア】
$userContent

【あなたの最初の指摘】
$originalFeedback

上記のあなたの指摘に対し、ユーザーがさらに興味を持っています。
その指摘をさらに「深彫り」して、具体的な改善案や、新たな視点、あるいは懸念点の詳細を3〜4つの短い段落(30〜80文字程度)で連続して語ってください。

【出力形式】
JSON Lines形式（1行に1つの文字列）で出力してください。
キーは "content" のみ。
例:
{"content": "もう少し具体的に言うと、...というリスクがあります。"}
{"content": "過去の事例で言うと、...が参考になるかもしれません。"}
''';

    try {
      final contentStream = _model.generateContentStream(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'text/plain',
          temperature: 0.8,
        ),
      );

      final lineStream = contentStream
          .map((response) => response.text ?? '')
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;
        if (cleanLine == '[' || cleanLine == ']') continue;

        try {
          final jsonStr =
              cleanLine.endsWith(',')
                  ? cleanLine.substring(0, cleanLine.length - 1)
                  : cleanLine;
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (json['content'] != null) {
            yield json['content'].toString();
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Fallback or rethrow
      rethrow;
    }
  }

  // Deprecated: Single Generation method (kept for reference or fallback if needed)
  Future<List<AiResponse>> generateResponses({
    required String userContent,
    required List<Persona> personas,
    String? context,
  }) async {
    // ... Redirect to stream or keep old impl?
    // For now, let's just collect the stream
    return generateResponsesStream(
      userContent: userContent,
      personas: personas,
      context: context,
    ).toList();
  }

  Sentiment _parseSentiment(dynamic value) {
    final str = (value ?? 'NEUTRAL').toString().toUpperCase();
    switch (str) {
      case 'POSITIVE':
        return Sentiment.positive;
      case 'NEGATIVE':
        return Sentiment.negative;
      default:
        return Sentiment.neutral;
    }
  }
}

/// AIサービスのプロバイダー
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// AI生成中フラグ
final isGeneratingProvider = StateProvider<bool>((ref) => false);

/// ペルソナ選抜プロバイダー（10名選抜）
final selectedPersonasProvider = Provider<List<Persona>>((ref) {
  return selectRandomPersonas(10);
});
