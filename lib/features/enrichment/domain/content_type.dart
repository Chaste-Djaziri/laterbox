import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

/// The smaller taxonomy LaterBox classifies an item into.
///
/// Schema.org (and other structured-data signals) are normalized into this
/// smaller set before reaching the Flutter app. The string values are what the
/// `enrich-url` edge function emits and what gets persisted in Drift.
enum ContentType {
  article,
  video,
  repository,
  product,
  place,
  event,
  book,
  music,
  link,
  unknown;

  /// Parse the string returned by the edge function into a [ContentType].
  /// Anything unknown degrades to [ContentType.unknown] (which maps to `link`).
  static ContentType fromString(String? value) {
    return switch (value) {
      'article' => article,
      'video' => video,
      'repository' => repository,
      'product' => product,
      'place' => place,
      'event' => event,
      'book' => book,
      'music' => music,
      'link' => link,
      _ => unknown,
    };
  }

  /// The canonical string persisted to Drift and sent to Supabase.
  String get value => name;

  /// Whether this type carries dedicated structured-data fields (e.g. brand
  /// for Product, startDate for Event).
  bool get hasStructuredData => switch (this) {
    ContentType.product => true,
    ContentType.event => true,
    ContentType.book => true,
    ContentType.music => true,
    ContentType.video => true,
    ContentType.repository => true,
    ContentType.article => true,
    ContentType.place => true,
    ContentType.link || ContentType.unknown => false,
  };

  /// A human-readable, display-ready label.
  String get label => switch (this) {
    ContentType.article => 'Article',
    ContentType.video => 'Video',
    ContentType.repository => 'Repository',
    ContentType.product => 'Product',
    ContentType.place => 'Place',
    ContentType.event => 'Event',
    ContentType.book => 'Book',
    ContentType.music => 'Music',
    ContentType.link => 'Link',
    ContentType.unknown => 'Unknown',
  };

  /// A small icon used in type labels and chip filters. Non-link/unknown types
  /// are the ones the Library "Types" section and Search filters surface.
  IconData get icon => switch (this) {
    ContentType.article => Icons.article_outlined,
    ContentType.video => Icons.play_circle_outline_rounded,
    ContentType.repository => Icons.code_rounded,
    ContentType.product => Icons.inventory_2_outlined,
    ContentType.place => Icons.place_outlined,
    ContentType.event => Icons.event_outlined,
    ContentType.book => Icons.menu_book_outlined,
    ContentType.music => Icons.music_note_outlined,
    ContentType.link => Icons.link_rounded,
    ContentType.unknown => Icons.question_mark_rounded,
  };
}

/// Where a classification originated.
enum ClassificationSource {
  domainRule,
  jsonLd,
  ogType,
  heuristic;

  static ClassificationSource fromString(String? value) => switch (value) {
    'domainRule' => ClassificationSource.domainRule,
    'jsonLd' => ClassificationSource.jsonLd,
    'ogType' => ClassificationSource.ogType,
    'heuristic' => ClassificationSource.heuristic,
    _ => ClassificationSource.heuristic,
  };

  String get value => name;
}

/// The result of classifying a URL. Carried through enrichment into Drift.
class ClassificationResult {
  const ClassificationResult({
    required this.type,
    required this.confidence,
    required this.source,
    this.structuredData,
  });

  /// Build from the raw `classification` object returned by `enrich-url`.
  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    final rawStructured = json['structuredData'];
    return ClassificationResult(
      type: ContentType.fromString(json['contentType'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      source: ClassificationSource.fromString(
        json['source'] as String?,
      ),
      structuredData: rawStructured == null
          ? null
          : Map<String, Object?>.from(rawStructured as Map),
    );
  }

  /// Build from a persisted [ItemMetadataData] row.
  factory ClassificationResult.fromDrift(ItemMetadataData row) {
    return ClassificationResult(
      type: ContentType.fromString(row.contentType),
      confidence: row.classificationConfidence,
      source: ClassificationSource.fromString(row.classificationSource),
      structuredData: ClassificationCodec.decode(row.structuredData),
    );
  }

  final ContentType type;

  /// 0.0–1.0, where 1.0 is the strongest possible signal.
  final double confidence;

  final ClassificationSource source;

  /// Allowlisted, type-specific structured-data payload. May be null when the
  /// classification has no useful structured data attached.
  final Map<String, Object?>? structuredData;

  ClassificationResult copyWith({
    ContentType? type,
    double? confidence,
    ClassificationSource? source,
    Map<String, Object?>? structuredData,
  }) {
    return ClassificationResult(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      structuredData: structuredData ?? this.structuredData,
    );
  }
}

/// JSON helpers kept here so both the data source and the repository can
/// serialize the allowlisted structured-data payload into a single text column.
class ClassificationCodec {
  const ClassificationCodec();

  static String encode(Map<String, Object?>? data) =>
      data == null ? '' : jsonEncode(data);

  static Map<String, Object?>? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, Object?> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}