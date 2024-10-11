// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WannaChatMessage _$WannaChatMessageFromJson(Map<String, dynamic> json) => WannaChatMessage(
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      message: json['message'] as String,
      citations:
          (json['citations'] as List<dynamic>?)?.map((e) => Citation.fromJson(e as Map<String, dynamic>)).toList() ??
              const [],
    );

Map<String, dynamic> _$WannaChatMessageToJson(WannaChatMessage instance) => <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type]!,
      'message': instance.message,
      'citations': instance.citations,
    };

const _$MessageTypeEnumMap = {
  MessageType.human: 'human',
  MessageType.ai: 'ai',
};
