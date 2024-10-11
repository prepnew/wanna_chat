import 'package:json_annotation/json_annotation.dart';

part 'cited_answer.g.dart';

@JsonSerializable()
class CitedAnswer {
  final String? answer;
  @JsonKey(defaultValue: [])
  final List<Citation> citations;

  CitedAnswer({required this.answer, required this.citations});

  static CitedAnswer fromJson(Map<String, dynamic> json) => _$CitedAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$CitedAnswerToJson(this);
}

@JsonSerializable()
class Citation {
  final String? source;
  final String? quote;

  Citation({required this.source, required this.quote});

  static Citation fromJson(Map<String, dynamic> json) => _$CitationFromJson(json);

  Map<String, dynamic> toJson() => _$CitationToJson(this);
}
