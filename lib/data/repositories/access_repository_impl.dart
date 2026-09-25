import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_messages.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/access_repository.dart';

class AccessRepositoryImpl implements AccessRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<bool> hasAccess() async {
    try {
      return await _client.rpc('is_member') as bool;
    } on PostgrestException catch (e) {
      // The database has not been upgraded with supabase/schema/ yet, so
      // there is no membership list to check against. The server's RLS is
      // what actually protects the data; this check only picks the screen.
      if (e.code == 'PGRST202' || e.code == '42883') return true;
      throw toAppException(e, 'Could not check your access.');
    } catch (e) {
      throw toAppException(e, 'Could not check your access.');
    }
  }

  @override
  Future<List<Member>> fetchMembers() async {
    try {
      final rows = await _client.rpc('list_members') as List;
      return [
        for (final row in rows) Member.fromMap(row as Map<String, dynamic>),
      ];
    } catch (e) {
      throw toAppException(e, 'Could not load the team.');
    }
  }

  @override
  Future<void> addMember(String email) async {
    try {
      await _client.rpc('add_member', params: {'p_email': email.trim()});
    } catch (e) {
      throw toAppException(e, 'Could not give access.');
    }
  }

  @override
  Future<void> removeMember(String userId) async {
    try {
      await _client.rpc('remove_member', params: {'p_user_id': userId});
    } catch (e) {
      throw toAppException(e, 'Could not remove access.');
    }
  }
}
