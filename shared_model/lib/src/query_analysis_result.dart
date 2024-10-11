import 'package:json_annotation/json_annotation.dart';

part 'query_analysis_result.g.dart';

@JsonSerializable()
class QueryAnalysisResult {
  final bool matchesVectorStoreTopics;
  final String vectorStoreQuery;

  QueryAnalysisResult({required this.matchesVectorStoreTopics, required this.vectorStoreQuery});

  static QueryAnalysisResult fromJson(Map<String, dynamic> json) => _$QueryAnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$QueryAnalysisResultToJson(this);
}
