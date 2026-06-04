import 'package:flutter/material.dart';

class Procedure {
  final String key;
  final String title;
  final String description;
  final List<String> steps;
  final List<String> requiredDocuments;
  final String cost;
  final String timeRequired;
  final String whereToGo;
  final String importantNotes;
  final IconData? icon;
  final String? titleKey;
  final String? subtitleKey;
  final List<String> keywords;

  Procedure({
    required this.key,
    required this.title,
    required this.description,
    required this.steps,
    required this.requiredDocuments,
    required this.cost,
    required this.timeRequired,
    required this.whereToGo,
    required this.importantNotes,
    this.icon,
    this.titleKey,
    this.subtitleKey,
    this.keywords = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'description': description,
      'steps': steps.join('||'),
      'required_documents': requiredDocuments.join('||'),
      'cost': cost,
      'time_required': timeRequired,
      'where_to_go': whereToGo,
      'important_notes': importantNotes,
    };
  }

  factory Procedure.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic value) {
      if (value == null) return const [];
      final raw = value.toString();
      if (raw.trim().isEmpty) return const [];

      return raw
          .split('||')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return Procedure(
      key: (map['key'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      steps: parseList(map['steps']),
      requiredDocuments:
          parseList(map['requiredDocuments'] ?? map['required_documents']),
      cost: (map['cost'] ?? '').toString(),
      timeRequired: (map['timeRequired'] ?? map['time_required'] ?? '')
          .toString(),
      whereToGo: (map['whereToGo'] ?? map['where_to_go'] ?? '').toString(),
      importantNotes:
          (map['importantNotes'] ?? map['important_notes'] ?? '').toString(),
      icon: null,
      titleKey: map['titleKey']?.toString(),
      subtitleKey: map['subtitleKey']?.toString(),
      keywords: List<String>.from(map['keywords'] ?? const []),
    );
  }
}
