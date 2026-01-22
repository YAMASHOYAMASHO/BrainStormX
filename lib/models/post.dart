import 'package:cloud_firestore/cloud_firestore.dart';

/// 投稿モデル
class Post {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String? targetResponseId;

  const Post({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.targetResponseId,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetResponseId: data['targetResponseId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetResponseId': targetResponseId,
    };
  }
}
