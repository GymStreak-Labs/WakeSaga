import 'package:flutter/material.dart';

enum AlarmCapabilityStatus { unknown, available, unavailable, denied }

enum AlarmLaunchSource { coldStart, warmAction, debug }

enum AlarmEventType { scheduled, cancelled, fired, opened, systemStopped }

enum AlarmOutcome { pending, clear, filler, knockdown, emergencyStop, unknown }

class AlarmCapabilityState {
  const AlarmCapabilityState({
    this.alarmKit = AlarmCapabilityStatus.unknown,
    this.notifications = AlarmCapabilityStatus.unknown,
    this.exactAlarm = AlarmCapabilityStatus.unknown,
    this.fullScreenIntent = AlarmCapabilityStatus.unknown,
    this.foregroundService = AlarmCapabilityStatus.unknown,
    this.compatibilityMode = false,
    this.message,
  });

  factory AlarmCapabilityState.fakeReady() => const AlarmCapabilityState(
    alarmKit: AlarmCapabilityStatus.unavailable,
    notifications: AlarmCapabilityStatus.available,
    exactAlarm: AlarmCapabilityStatus.available,
    fullScreenIntent: AlarmCapabilityStatus.available,
    foregroundService: AlarmCapabilityStatus.available,
    compatibilityMode: true,
    message: 'Prototype alarm engine ready',
  );

  final AlarmCapabilityStatus alarmKit;
  final AlarmCapabilityStatus notifications;
  final AlarmCapabilityStatus exactAlarm;
  final AlarmCapabilityStatus fullScreenIntent;
  final AlarmCapabilityStatus foregroundService;
  final bool compatibilityMode;
  final String? message;

  bool get canSchedule =>
      alarmKit == AlarmCapabilityStatus.available ||
      exactAlarm == AlarmCapabilityStatus.available ||
      notifications == AlarmCapabilityStatus.available;

  Map<String, Object?> toJson() => {
    'alarmKit': alarmKit.name,
    'notifications': notifications.name,
    'exactAlarm': exactAlarm.name,
    'fullScreenIntent': fullScreenIntent.name,
    'foregroundService': foregroundService.name,
    'compatibilityMode': compatibilityMode,
    'message': message,
  };
}

class AlarmPlan {
  const AlarmPlan({
    required this.id,
    required this.episode,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.quest,
    required this.mission,
    required this.narrator,
    required this.joltAssetPath,
    this.episodeVoiceAssetPath,
    this.episodeMusicAssetPath,
    this.episodeMixAssetPath,
    required this.fallbackQuest,
    required this.createdAt,
  });

  final String id;
  final int episode;
  final int hour;
  final int minute;
  final List<int> repeatDays;
  final String quest;
  final String mission;
  final String narrator;
  final String? joltAssetPath;
  final String? episodeVoiceAssetPath;
  final String? episodeMusicAssetPath;
  final String? episodeMixAssetPath;
  final String fallbackQuest;
  final DateTime createdAt;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get timeLabel {
    final t = time;
    final displayHour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final displayMinute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$displayHour:$displayMinute $period';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'episode': episode,
    'hour': hour,
    'minute': minute,
    'repeatDays': repeatDays,
    'quest': quest,
    'mission': mission,
    'narrator': narrator,
    'joltAssetPath': joltAssetPath,
    'episodeVoiceAssetPath': episodeVoiceAssetPath,
    'episodeMusicAssetPath': episodeMusicAssetPath,
    'episodeMixAssetPath': episodeMixAssetPath,
    'fallbackQuest': fallbackQuest,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AlarmPlan.fromJson(Map<String, Object?> json) {
    return AlarmPlan(
      id: json['id'] as String? ?? 'wake-episode',
      episode: (json['episode'] as num?)?.toInt() ?? 1,
      hour: (json['hour'] as num?)?.toInt() ?? 6,
      minute: (json['minute'] as num?)?.toInt() ?? 30,
      repeatDays:
          (json['repeatDays'] as List?)
              ?.whereType<num>()
              .map((value) => value.toInt())
              .toList() ??
          const [],
      quest: json['quest'] as String? ?? 'Get Up',
      mission: json['mission'] as String? ?? 'Finish the essay outline',
      narrator: json['narrator'] as String? ?? 'Mentor',
      joltAssetPath: json['joltAssetPath'] as String?,
      episodeVoiceAssetPath: json['episodeVoiceAssetPath'] as String?,
      episodeMusicAssetPath: json['episodeMusicAssetPath'] as String?,
      episodeMixAssetPath: json['episodeMixAssetPath'] as String?,
      fallbackQuest: json['fallbackQuest'] as String? ?? 'Shake',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ScheduledAlarm {
  const ScheduledAlarm({
    required this.plan,
    required this.scheduledFor,
    required this.engineMode,
  });

  final AlarmPlan plan;
  final DateTime scheduledFor;
  final String engineMode;

  Map<String, Object?> toJson() => {
    'plan': plan.toJson(),
    'scheduledFor': scheduledFor.toIso8601String(),
    'engineMode': engineMode,
  };

  factory ScheduledAlarm.fromJson(Map<String, Object?> json) {
    return ScheduledAlarm(
      plan: AlarmPlan.fromJson(
        Map<String, Object?>.from(json['plan'] as Map? ?? const {}),
      ),
      scheduledFor:
          DateTime.tryParse(json['scheduledFor'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      engineMode: json['engineMode'] as String? ?? 'unknown',
    );
  }
}

class AlarmLaunch {
  const AlarmLaunch({
    required this.alarmId,
    required this.source,
    required this.launchedAt,
  });

  final String alarmId;
  final AlarmLaunchSource source;
  final DateTime launchedAt;
}

class AlarmEvent {
  const AlarmEvent({
    required this.type,
    required this.alarmId,
    required this.occurredAt,
  });

  final AlarmEventType type;
  final String alarmId;
  final DateTime occurredAt;
}

class ExpectedFireRecord {
  const ExpectedFireRecord({
    required this.alarmId,
    required this.scheduledFor,
    this.actualLaunchAt,
    this.osStoppedAt,
    this.questClearedAt,
    this.outcome = AlarmOutcome.pending,
  });

  final String alarmId;
  final DateTime scheduledFor;
  final DateTime? actualLaunchAt;
  final DateTime? osStoppedAt;
  final DateTime? questClearedAt;
  final AlarmOutcome outcome;

  ExpectedFireRecord copyWith({
    DateTime? actualLaunchAt,
    DateTime? osStoppedAt,
    DateTime? questClearedAt,
    AlarmOutcome? outcome,
  }) {
    return ExpectedFireRecord(
      alarmId: alarmId,
      scheduledFor: scheduledFor,
      actualLaunchAt: actualLaunchAt ?? this.actualLaunchAt,
      osStoppedAt: osStoppedAt ?? this.osStoppedAt,
      questClearedAt: questClearedAt ?? this.questClearedAt,
      outcome: outcome ?? this.outcome,
    );
  }

  Map<String, Object?> toJson() => {
    'alarmId': alarmId,
    'scheduledFor': scheduledFor.toIso8601String(),
    'actualLaunchAt': actualLaunchAt?.toIso8601String(),
    'osStoppedAt': osStoppedAt?.toIso8601String(),
    'questClearedAt': questClearedAt?.toIso8601String(),
    'outcome': outcome.name,
  };

  factory ExpectedFireRecord.fromJson(Map<String, Object?> json) {
    return ExpectedFireRecord(
      alarmId: json['alarmId'] as String? ?? 'unknown',
      scheduledFor:
          DateTime.tryParse(json['scheduledFor'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actualLaunchAt: DateTime.tryParse(
        json['actualLaunchAt'] as String? ?? '',
      ),
      osStoppedAt: DateTime.tryParse(json['osStoppedAt'] as String? ?? ''),
      questClearedAt: DateTime.tryParse(
        json['questClearedAt'] as String? ?? '',
      ),
      outcome: AlarmOutcome.values.firstWhere(
        (value) => value.name == json['outcome'],
        orElse: () => AlarmOutcome.pending,
      ),
    );
  }
}
