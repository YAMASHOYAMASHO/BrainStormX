import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

// Model for a single feedback/response item in a thread
class ThreadItem {
  final String content;
  final String authorName; // Persona or User
  final DateTime timestamp;

  ThreadItem({
    required this.content,
    required this.authorName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'authorName': authorName,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ThreadItem.fromJson(Map<String, dynamic> json) {
    return ThreadItem(
      content: json['content'],
      authorName: json['authorName'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Model for an Idea Thread (The "Sculpture" Project)
class IdeaThread {
  final String id;
  final String title; // The original idea
  final DateTime createdAt;
  final List<ThreadItem> pinnedItems;

  IdeaThread({
    required this.id,
    required this.title,
    required this.createdAt,
    this.pinnedItems = const [],
  });

  IdeaThread copyWith({List<ThreadItem>? pinnedItems}) {
    return IdeaThread(
      id: id,
      title: title,
      createdAt: createdAt,
      pinnedItems: pinnedItems ?? this.pinnedItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'pinnedItems': pinnedItems.map((e) => e.toJson()).toList(),
  };

  factory IdeaThread.fromJson(Map<String, dynamic> json) {
    return IdeaThread(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      pinnedItems:
          (json['pinnedItems'] as List<dynamic>?)
              ?.map((e) => ThreadItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class IdeaRepositoryNotifier extends StateNotifier<List<IdeaThread>> {
  IdeaRepositoryNotifier() : super([]) {
    _load();
  }

  static const _key = 'sclup_idea_threads';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      state = jsonList.map((e) => IdeaThread.fromJson(e)).toList();
    }
  }

  // Create a new Idea Thread
  Future<String> createIdea(String title) async {
    final newIdea = IdeaThread(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    state = [newIdea, ...state];
    await _save();
    return newIdea.id;
  }

  // Pin a feedback item to a specific thread
  Future<void> pinItem(String ideaId, String content, String authorName) async {
    state =
        state.map((idea) {
          if (idea.id == ideaId) {
            // Prevent duplicates
            if (idea.pinnedItems.any((item) => item.content == content))
              return idea;

            final newItem = ThreadItem(
              content: content,
              authorName: authorName,
              timestamp: DateTime.now(),
            );
            return idea.copyWith(pinnedItems: [...idea.pinnedItems, newItem]);
          }
          return idea;
        }).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}

final ideaRepositoryProvider =
    StateNotifierProvider<IdeaRepositoryNotifier, List<IdeaThread>>((ref) {
      return IdeaRepositoryNotifier();
    });
