import 'package:flutter/foundation.dart';

/// Domain entity representing an agronomy dictionary / glossary term.
@immutable
class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.meaning,
    this.category,
  });

  final String term;
  final String meaning;
  final String? category;
}
