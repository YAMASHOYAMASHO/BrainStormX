/// ペルソナカテゴリ
enum PersonaCategory {
  positive, // 肯定的
  negative, // 否定的
  analytical, // 分析的
}

/// ペルソナモデル
class Persona {
  final String id;
  final String name;
  final String systemPrompt;
  final PersonaCategory category;
  final String occupation;
  final String tone;

  const Persona({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.category,
    required this.occupation,
    required this.tone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'category': category.name,
      'occupation': occupation,
      'tone': tone,
    };
  }
}
