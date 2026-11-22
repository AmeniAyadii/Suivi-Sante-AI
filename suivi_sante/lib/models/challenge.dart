class Challenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String colorHex;
  final int participantsCount;
  final int completionRate;
  final DateTime startDate;
  final DateTime endDate;
  final bool isJoined;
  final bool isCompleted;
  final List<ChallengeReward> rewards;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorHex,
    required this.participantsCount,
    required this.completionRate,
    required this.startDate,
    required this.endDate,
    this.isJoined = false,
    this.isCompleted = false,
    this.rewards = const [],
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  String get daysRemaining {
    final difference = endDate.difference(DateTime.now());
    return '${difference.inDays} jours restants';
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? '🏆',
      colorHex: json['color_hex'] ?? '#FF6B6B',
      participantsCount: json['participants_count'] ?? 0,
      completionRate: json['completion_rate'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isJoined: json['is_joined'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      rewards: (json['rewards'] as List?)
          ?.map((e) => ChallengeReward.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ChallengeReward {
  final String id;
  final String title;
  final String type;
  final int value;

  ChallengeReward({
    required this.id,
    required this.title,
    required this.type,
    required this.value,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      id: json['id'].toString(),
      title: json['title'],
      type: json['type'],
      value: json['value'],
    );
  }
}