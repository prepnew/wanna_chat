// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryAnalysisResult _$QueryAnalysisResultFromJson(Map<String, dynamic> json) => QueryAnalysisResult(
      matchesVectorStoreTopics: json['matchesVectorStoreTopics'] as bool,
      vectorStoreQuery: json['vectorStoreQuery'] as String,
    );

Map<String, dynamic> _$QueryAnalysisResultToJson(QueryAnalysisResult instance) => <String, dynamic>{
      'matchesVectorStoreTopics': instance.matchesVectorStoreTopics,
      'vectorStoreQuery': instance.vectorStoreQuery,
    };
