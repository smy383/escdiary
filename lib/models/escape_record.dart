import 'package:uuid/uuid.dart';
import 'detail_memo.dart';

// 클리어 시간 타입
enum ClearTimeType {
  remaining, // 남은 시간
  elapsed,   // 걸린 시간
}

class EscapeRecord {
  final String id;
  final String themeName; // 테마명
  final String storeName; // 매장명
  final String? branchName; // 지점명
  final DateTime playDate; // 플레이 날짜
  final int playTime; // 플레이 시간 (분)
  final int playerCount; // 인원 수
  final bool isCleared; // 탈출 성공 여부
  final int? hintCount; // 힌트 사용 횟수
  final String? clearTime; // 클리어 시간 (예: "45:30")
  final ClearTimeType clearTimeType; // 남은 시간 or 걸린 시간

  // 평점 (1-5점)
  final double ratingInterior; // 인테리어
  final double ratingSatisfaction; // 만족도
  final double ratingPuzzle; // 문제
  final double ratingStory; // 스토리
  final double ratingProduction; // 연출
  final double ratingHorror; // 공포

  // 상세 내용
  final String? content; // 간단 메모
  final List<DetailMemo>? detailMemos; // 상세 메모 (스토리, 연출, 문제, 정답)
  final List<String>? tags; // 태그
  final DateTime createdAt;
  final DateTime updatedAt;

  EscapeRecord({
    String? id,
    required this.themeName,
    required this.storeName,
    this.branchName,
    required this.playDate,
    required this.playTime,
    required this.playerCount,
    required this.isCleared,
    this.hintCount,
    this.clearTime,
    this.clearTimeType = ClearTimeType.remaining,
    this.ratingInterior = 0,
    this.ratingSatisfaction = 0,
    this.ratingPuzzle = 0,
    this.ratingStory = 0,
    this.ratingProduction = 0,
    this.ratingHorror = 0,
    this.content,
    this.detailMemos,
    this.tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 평균 평점 계산
  double get averageRating {
    final ratings = [
      ratingInterior,
      ratingSatisfaction,
      ratingPuzzle,
      ratingStory,
      ratingProduction,
      ratingHorror,
    ];
    final validRatings = ratings.where((r) => r > 0).toList();
    if (validRatings.isEmpty) return 0;
    return validRatings.reduce((a, b) => a + b) / validRatings.length;
  }

  // 전체 위치 문자열
  String get fullLocation {
    if (branchName != null && branchName!.isNotEmpty) {
      return '$storeName $branchName';
    }
    return storeName;
  }

  // 남은 시간 계산 (걸린 시간으로 기록된 경우 제한시간에서 빼서 계산)
  String? get remainingTime {
    if (clearTime == null || clearTime!.isEmpty) return null;

    if (clearTimeType == ClearTimeType.remaining) {
      return clearTime;
    }

    // 걸린 시간 -> 남은 시간 계산
    try {
      final parts = clearTime!.split(':');
      if (parts.length != 2) return clearTime;

      final elapsedMinutes = int.parse(parts[0]);
      final elapsedSeconds = int.parse(parts[1]);
      final totalElapsedSeconds = elapsedMinutes * 60 + elapsedSeconds;
      final limitSeconds = playTime * 60;
      final remainingSeconds = limitSeconds - totalElapsedSeconds;

      if (remainingSeconds < 0) return '0:00';

      final mins = remainingSeconds ~/ 60;
      final secs = remainingSeconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    } catch (e) {
      return clearTime;
    }
  }

  // copyWith
  EscapeRecord copyWith({
    String? id,
    String? themeName,
    String? storeName,
    String? branchName,
    DateTime? playDate,
    int? playTime,
    int? playerCount,
    bool? isCleared,
    int? hintCount,
    String? clearTime,
    ClearTimeType? clearTimeType,
    double? ratingInterior,
    double? ratingSatisfaction,
    double? ratingPuzzle,
    double? ratingStory,
    double? ratingProduction,
    double? ratingHorror,
    String? content,
    List<DetailMemo>? detailMemos,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EscapeRecord(
      id: id ?? this.id,
      themeName: themeName ?? this.themeName,
      storeName: storeName ?? this.storeName,
      branchName: branchName ?? this.branchName,
      playDate: playDate ?? this.playDate,
      playTime: playTime ?? this.playTime,
      playerCount: playerCount ?? this.playerCount,
      isCleared: isCleared ?? this.isCleared,
      hintCount: hintCount ?? this.hintCount,
      clearTime: clearTime ?? this.clearTime,
      clearTimeType: clearTimeType ?? this.clearTimeType,
      ratingInterior: ratingInterior ?? this.ratingInterior,
      ratingSatisfaction: ratingSatisfaction ?? this.ratingSatisfaction,
      ratingPuzzle: ratingPuzzle ?? this.ratingPuzzle,
      ratingStory: ratingStory ?? this.ratingStory,
      ratingProduction: ratingProduction ?? this.ratingProduction,
      ratingHorror: ratingHorror ?? this.ratingHorror,
      content: content ?? this.content,
      detailMemos: detailMemos ?? this.detailMemos,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'themeName': themeName,
      'storeName': storeName,
      'branchName': branchName,
      'playDate': playDate.toIso8601String(),
      'playTime': playTime,
      'playerCount': playerCount,
      'isCleared': isCleared ? 1 : 0,
      'hintCount': hintCount,
      'clearTime': clearTime,
      'clearTimeType': clearTimeType.index,
      'ratingInterior': ratingInterior,
      'ratingSatisfaction': ratingSatisfaction,
      'ratingPuzzle': ratingPuzzle,
      'ratingStory': ratingStory,
      'ratingProduction': ratingProduction,
      'ratingHorror': ratingHorror,
      'content': content,
      'detailMemos': detailMemos != null ? DetailMemo.listToJson(detailMemos!) : null,
      'tags': tags?.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EscapeRecord.fromJson(Map<String, dynamic> json) {
    return EscapeRecord(
      id: json['id'] as String,
      themeName: json['themeName'] as String,
      storeName: json['storeName'] as String,
      branchName: json['branchName'] as String?,
      playDate: DateTime.parse(json['playDate'] as String),
      playTime: json['playTime'] as int,
      playerCount: json['playerCount'] as int,
      isCleared: json['isCleared'] == 1,
      hintCount: json['hintCount'] as int?,
      clearTime: json['clearTime'] as String?,
      clearTimeType: ClearTimeType.values[json['clearTimeType'] as int? ?? 0],
      ratingInterior: (json['ratingInterior'] as num?)?.toDouble() ?? 0,
      ratingSatisfaction: (json['ratingSatisfaction'] as num?)?.toDouble() ?? 0,
      ratingPuzzle: (json['ratingPuzzle'] as num?)?.toDouble() ?? 0,
      ratingStory: (json['ratingStory'] as num?)?.toDouble() ?? 0,
      ratingProduction: (json['ratingProduction'] as num?)?.toDouble() ?? 0,
      ratingHorror: (json['ratingHorror'] as num?)?.toDouble() ?? 0,
      content: json['content'] as String?,
      detailMemos: DetailMemo.listFromJson(json['detailMemos'] as String?),
      tags: json['tags'] != null && (json['tags'] as String).isNotEmpty
          ? (json['tags'] as String).split(',')
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
