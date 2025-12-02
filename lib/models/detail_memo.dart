import 'dart:convert';

enum MemoType {
  story,      // 스토리
  production, // 연출
  puzzle,     // 문제
  answer,     // 정답
}

extension MemoTypeExtension on MemoType {
  String get label {
    switch (this) {
      case MemoType.story:
        return '스토리';
      case MemoType.production:
        return '연출';
      case MemoType.puzzle:
        return '문제';
      case MemoType.answer:
        return '정답';
    }
  }

  String get prefix {
    switch (this) {
      case MemoType.story:
        return 'S';
      case MemoType.production:
        return 'P';
      case MemoType.puzzle:
        return 'Q';
      case MemoType.answer:
        return 'A';
    }
  }
}

class DetailMemo {
  final MemoType type;
  final int number; // 해당 타입의 몇 번째인지 (1, 2, 3...)
  final String content;

  DetailMemo({
    required this.type,
    required this.number,
    required this.content,
  });

  String get title => '${type.label}$number';

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'number': number,
      'content': content,
    };
  }

  factory DetailMemo.fromJson(Map<String, dynamic> json) {
    return DetailMemo(
      type: MemoType.values[json['type'] as int],
      number: json['number'] as int,
      content: json['content'] as String,
    );
  }

  DetailMemo copyWith({
    MemoType? type,
    int? number,
    String? content,
  }) {
    return DetailMemo(
      type: type ?? this.type,
      number: number ?? this.number,
      content: content ?? this.content,
    );
  }

  // List<DetailMemo>를 JSON 문자열로 변환
  static String listToJson(List<DetailMemo> memos) {
    return jsonEncode(memos.map((m) => m.toJson()).toList());
  }

  // JSON 문자열을 List<DetailMemo>로 변환
  static List<DetailMemo> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DetailMemo.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
