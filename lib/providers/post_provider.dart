import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/response.dart';
import 'auth_provider.dart';
import 'project_provider.dart';

/// 選択中のプロジェクトID
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

/// 投稿一覧のストリーム
final postsStreamProvider = StreamProvider.family<List<Post>, String>((
  ref,
  projectId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('projects')
      .doc(projectId)
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
      );
});

/// 特定投稿のレスポンス一覧ストリーム
final responsesStreamProvider = StreamProvider.family<
  List<AiResponse>,
  ({String projectId, String postId})
>((ref, params) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('projects')
      .doc(params.projectId)
      .collection('posts')
      .doc(params.postId)
      .collection('responses')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => AiResponse.fromFirestore(doc)).toList(),
      );
});

/// 投稿リポジトリ
class PostRepository {
  final FirebaseFirestore _firestore;

  PostRepository(this._firestore);

  DocumentReference _postRef(String uid, String projectId, String postId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId)
        .collection('posts')
        .doc(postId);
  }

  CollectionReference _postsRef(String uid, String projectId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId)
        .collection('posts');
  }

  /// 投稿作成
  Future<String> createPost(
    String uid,
    String projectId,
    String content, {
    String? targetResponseId,
  }) async {
    final doc = await _postsRef(uid, projectId).add({
      'content': content,
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'targetResponseId': targetResponseId,
    });
    return doc.id;
  }

  /// レスポンスを保存
  Future<void> saveResponses(
    String uid,
    String projectId,
    String postId,
    List<AiResponse> responses,
  ) async {
    final batch = _firestore.batch();
    final responsesRef = _postRef(
      uid,
      projectId,
      postId,
    ).collection('responses');

    for (final response in responses) {
      final docRef = responsesRef.doc();
      batch.set(docRef, response.toFirestore());
    }

    await batch.commit();
  }

  /// リツイート状態を更新
  Future<void> toggleRetweet(
    String uid,
    String projectId,
    String postId,
    String responseId,
    bool isRetweeted,
  ) async {
    await _postRef(uid, projectId, postId)
        .collection('responses')
        .doc(responseId)
        .update({'isRetweeted': isRetweeted});
  }
}

/// 投稿リポジトリのプロバイダー
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(firestoreProvider));
});
