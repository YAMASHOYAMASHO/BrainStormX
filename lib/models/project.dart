import 'package:cloud_firestore/cloud_firestore.dart';

/// プロジェクトモデル（思考スレッド）
class Project {
  final String id;
  final String title;
  final DateTime lastActivity;
  final String? contextSummary;

  const Project({
    required this.id,
    required this.title,
    required this.lastActivity,
    this.contextSummary,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      title: data['title'] ?? '',
      lastActivity:
          (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contextSummary: data['contextSummary'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'contextSummary': contextSummary,
    };
  }

  Project copyWith({
    String? id,
    String? title,
    DateTime? lastActivity,
    String? contextSummary,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      lastActivity: lastActivity ?? this.lastActivity,
      contextSummary: contextSummary ?? this.contextSummary,
    );
  }
}
