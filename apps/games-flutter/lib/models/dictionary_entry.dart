class DictionaryEntry {
  final String mot;
  final List<Definition> definitions;

  DictionaryEntry({
    required this.mot,
    required this.definitions,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      mot: json['mot'] as String,
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Definition {
  final int sensNum;
  final String nature;
  final String traduction;

  Definition({
    required this.sensNum,
    required this.nature,
    required this.traduction,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      sensNum: json['sens_num'] as int,
      nature: json['nature'] as String,
      traduction: json['traduction'] as String,
    );
  }
}
