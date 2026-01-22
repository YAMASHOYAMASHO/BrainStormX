/// ユーザーモデル
class AppUser {
  final String uid;
  final bool isPremium;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    this.isPremium = false,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      isPremium: data['isPremium'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'isPremium': isPremium, 'createdAt': createdAt};
  }
}
