// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqInput _$FaqInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'FaqInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'expectedUpdatedAt',
            'topic',
            'question',
            'answer',
            'published'
          ],
        );
        final val = FaqInput(
          expectedUpdatedAt:
              $checkedConvert('expectedUpdatedAt', (v) => v as String?),
          topic: $checkedConvert('topic', (v) => v as String),
          question: $checkedConvert('question', (v) => v as String),
          answer: $checkedConvert('answer', (v) => v as String),
          published: $checkedConvert('published', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$FaqInputToJson(FaqInput instance) => <String, dynamic>{
      'expectedUpdatedAt': instance.expectedUpdatedAt,
      'topic': instance.topic,
      'question': instance.question,
      'answer': instance.answer,
      'published': instance.published,
    };
