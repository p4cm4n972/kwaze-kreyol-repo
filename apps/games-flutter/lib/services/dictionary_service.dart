import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/dictionary_entry.dart';

class DictionaryService {
  /// Charge le dictionnaire depuis les assets Flutter
  Future<List<DictionaryEntry>> loadDictionary(String letter) async {
    try {
      final contents = await rootBundle.loadString(
        'assets/data/dictionnaire_$letter.json',
      );

      final List<dynamic> jsonData = json.decode(contents);
      return jsonData
          .map((entry) =>
              DictionaryEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading dictionary: $e');
      return [];
    }
  }

  /// Pour la version web, on charge depuis une URL
  Future<List<DictionaryEntry>> loadDictionaryFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((entry) =>
                DictionaryEntry.fromJson(entry as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error loading dictionary from URL: $e');
      return [];
    }
  }

  List<String> getRandomWords(List<DictionaryEntry> entries, int count) {
    final shuffled = List<DictionaryEntry>.from(entries)..shuffle();
    return shuffled.take(count).map((e) => e.mot).toList();
  }
}
