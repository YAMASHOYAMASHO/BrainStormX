import 'package:cloud_firestore/cloud_firestore.dart';

/// AIレスポンスタイプ
enum ResponseType { reply, quote }

/// センチメントタイプ
enum Sentiment { positive, negative, neutral }

/// AIレスポンスモデル
class AiResponse {
  final String id;
  final String personaId;
  final String personaName;
  final ResponseType type;
  final String content;
  final Sentiment sentiment;
  final bool isRetweeted;
  final DateTime createdAt;

  const AiResponse({
    required this.id,
    required this.personaId,
    required this.personaName,
    required this.type,
    required this.content,
    required this.sentiment,
    this.isRetweeted = false,
    required this.createdAt,
  });

  factory AiResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiResponse(
      id: doc.id,
      personaId: data['personaId'] ?? '',
      personaName: data['personaName'] ?? '',
      type: ResponseType.values.firstWhere(
        (e) => e.name.toUpperCase() == (data['type'] ?? 'REPLY'),
        orElse: () => ResponseType.reply,
      ),
      content: data['content'] ?? '',
      sentiment: Sentiment.values.firstWhere(
        (e) => e.name.toUpperCase() == (data['sentiment'] ?? 'NEUTRAL'),
        orElse: () => Sentiment.neutral,
      ),
      isRetweeted: data['isRetweeted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personaId': personaId,
      'personaName': personaName,
      'type': type.name.toUpperCase(),
      'content': content,
      'sentiment': sentiment.name.toUpperCase(),
      'isRetweeted': isRetweeted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AiResponse copyWith({bool? isRetweeted}) {
    return AiResponse(
      id: id,
      personaId: personaId,
      personaName: personaName,
      type: type,
      content: content,
      sentiment: sentiment,
      isRetweeted: isRetweeted ?? this.isRetweeted,
      createdAt: createdAt,
    );
  }
}
