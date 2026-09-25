import '../entities/member.dart';

abstract interface class AccessRepository {
  /// Whether the signed-in account may use the store.
  Future<bool> hasAccess();

  Future<List<Member>> fetchMembers();
  Future<void> addMember(String email);
  Future<void> removeMember(String userId);
}
