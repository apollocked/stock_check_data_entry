/// An account that has access to the store (see `public.members`).
class Member {
  final String userId;
  final String email;
  final DateTime addedAt;
  final bool isMe;

  const Member({
    required this.userId,
    required this.email,
    required this.addedAt,
    this.isMe = false,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      userId: map['user_id'] as String,
      email: map['email'] as String? ?? '',
      addedAt: DateTime.parse(map['added_at'] as String).toLocal(),
      isMe: map['is_me'] as bool? ?? false,
    );
  }
}
