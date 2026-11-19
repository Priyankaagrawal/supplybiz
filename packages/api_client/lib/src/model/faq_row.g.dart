// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqRow _$FaqRowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'FaqRow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'topic',
            'question',
            'answer',
            'published',
            'updatedAt'
          ],
        );
        final val = FaqRow(
          id: $checkedConvert('id', (v) => v as String),
          topic: $checkedConvert('topic', (v) => v as String),
          question: $checkedConvert('question', (v) => v as String),
          answer: $checkedConvert('answer', (v) => v as String),
          published: $checkedConvert('published', (v) => v as bool),
          updatedAt:
              $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$FaqRowToJson(FaqRow instance) => <String, dynamic>{
      'id': instance.id,
      'topic': instance.topic,
      'question': instance.question,
      'answer': instance.answer,
      'published': instance.published,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
