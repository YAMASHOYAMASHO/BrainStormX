import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'auth_provider.dart';

/// Firestore インスタンス
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// プロジェクト一覧のストリーム
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('projects')
      .orderBy('lastActivity', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList(),
      );
});

/// プロジェクトリポジトリ
class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository(this._firestore);

  CollectionReference _projectsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('projects');
  }

  /// プロジェクト作成
  Future<String> createProject(String uid, String title) async {
    final doc = await _projectsRef(uid).add({
      'title': title,
      'lastActivity': FieldValue.serverTimestamp(),
      'contextSummary': null,
    });
    return doc.id;
  }

  /// プロジェクト更新
  Future<void> updateProject(String uid, Project project) async {
    await _projectsRef(uid).doc(project.id).update(project.toFirestore());
  }

  /// プロジェクト削除
  Future<void> deleteProject(String uid, String projectId) async {
    await _projectsRef(uid).doc(projectId).delete();
  }

  /// 最終活動日時を更新
  Future<void> updateLastActivity(String uid, String projectId) async {
    await _projectsRef(
      uid,
    ).doc(projectId).update({'lastActivity': FieldValue.serverTimestamp()});
  }
}

/// プロジェクトリポジトリのプロバイダー
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(firestoreProvider));
});
