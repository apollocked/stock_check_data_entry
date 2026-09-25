/// Client-side rule for new passwords. Supabase enforces its own minimum too;
/// set Authentication -> Providers -> Email -> "Minimum password length" to 8
/// (and require letters and digits) so the server agrees.
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Use at least 8 characters';
  if (password.length > 72) return 'Use 72 characters or fewer';
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  if (!hasLetter || !hasDigit) return 'Mix letters and numbers';
  return null;
}
