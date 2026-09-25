import '../config.dart';

/// Whether an item image URL may be loaded.
///
/// `image_url` is a plain column any member can write, so without this check a
/// row could make every phone that opens the inventory fetch an arbitrary
/// address. Only HTTPS links to this project's own Supabase host are loaded.
bool isTrustedImageUrl(String? url, {String supabaseUrl = Config.supabaseUrl}) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  final project = Uri.tryParse(supabaseUrl);
  if (uri == null || project == null || project.host.isEmpty) return false;
  return uri.scheme == 'https' && uri.host == project.host;
}
