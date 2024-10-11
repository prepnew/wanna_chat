// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cited_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CitedAnswer _$CitedAnswerFromJson(Map<String, dynamic> json) => CitedAnswer(
      answer: json['answer'] as String?,
      citations:
          (json['citations'] as List<dynamic>?)?.map((e) => Citation.fromJson(e as Map<String, dynamic>)).toList() ??
              [],
    );

Map<String, dynamic> _$CitedAnswerToJson(CitedAnswer instance) => <String, dynamic>{
      'answer': instance.answer,
      'citations': instance.citations,
    };

Citation _$CitationFromJson(Map<String, dynamic> json) => Citation(
      source: json['source'] as String?,
      quote: json['quote'] as String?,
    );

Map<String, dynamic> _$CitationToJson(Citation instance) => <String, dynamic>{
      'source': instance.source,
      'quote': instance.quote,
    };
