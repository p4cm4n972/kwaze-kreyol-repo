class DictionaryWord {
  final String id;
  final String word;
  final String language; // 'creole' ou 'francais'
  final String translation;
  final String? nature; // Nom, verbe, adjectif...
  final String? example;
  final String? source;
  final bool isOfficial;
  final DateTime createdAt;

  DictionaryWord({
    required this.id,
    required this.word,
    required this.language,
    required this.translation,
    this.nature,
    this.example,
    this.source,
    this.isOfficial = true,
    required this.createdAt,
  });

  factory DictionaryWord.fromJson(Map<String, dynamic> json) {
    return DictionaryWord(
      id: json['id'] as String,
      word: json['word'] as String,
      language: json['language'] as String? ?? 'creole',
      translation: json['translation'] as String,
      nature: json['nature'] as String?,
      example: json['example'] as String?,
      source: json['source'] as String?,
      isOfficial: json['is_official'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'language': language,
      'translation': translation,
      'nature': nature,
      'example': example,
      'source': source,
      'is_official': isOfficial,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DictionaryContribution {
  final String id;
  final String userId;
  final String word;
  final String translation;
  final String? nature;
  final String? example;
  final String status; // pending, approved, rejected
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  DictionaryContribution({
    required this.id,
    required this.userId,
    required this.word,
    required this.translation,
    this.nature,
    this.example,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  factory DictionaryContribution.fromJson(Map<String, dynamic> json) {
    return DictionaryContribution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      nature: json['nature'] as String?,
      example: json['example'] as String?,
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewNotes: json['review_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'word': word,
      'translation': translation,
      'nature': nature,
      'example': example,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}
