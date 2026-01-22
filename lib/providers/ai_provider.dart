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

  /// ペルソナ達からのレスポンスを生成
  Future<List<AiResponse>> generateResponses({
    required String userContent,
    required List<Persona> personas,
    String? context,
  }) async {
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
- 出力は必ずJSON配列形式で。

【参加ペルソナリスト】
$personaListText

【ユーザー投稿】
$userContent$contextSection

【出力フォーマット】
以下のJSON配列形式で出力してください:
[
  {
    "personaId": "ペルソナのID",
    "personaName": "表示名",
    "type": "REPLY または QUOTE",
    "content": "反応内容（50-150文字程度）",
    "sentiment": "POSITIVE, NEGATIVE, NEUTRAL のいずれか"
  }
]

全てのペルソナについて反応を生成してください。
''';

    try {
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.9,
        ),
      );

      final text = response.text;
      if (text == null) return [];

      final List<dynamic> jsonList = jsonDecode(text);
      final now = DateTime.now();

      return jsonList.asMap().entries.map((entry) {
        final i = entry.key;
        final json = entry.value as Map<String, dynamic>;
        return AiResponse(
          id: 'temp_${now.millisecondsSinceEpoch}_$i',
          personaId: json['personaId'] ?? '',
          personaName: json['personaName'] ?? '',
          type:
              (json['type'] ?? 'REPLY').toString().toUpperCase() == 'QUOTE'
                  ? ResponseType.quote
                  : ResponseType.reply,
          content: json['content'] ?? '',
          sentiment: _parseSentiment(json['sentiment']),
          isRetweeted: false,
          createdAt: now.add(Duration(milliseconds: i * 100)),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
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
