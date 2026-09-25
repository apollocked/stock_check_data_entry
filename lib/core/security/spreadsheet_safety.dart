/// Stops a cell from being run as a formula when an export is opened in
/// Excel, Sheets or LibreOffice (CSV / formula injection).
///
/// Item names, notes and custom fields are typed by users, so a value such as
/// `=HYPERLINK("http://evil", "Click")` would otherwise become a live formula
/// on whoever opens the file. Prefixing a quote makes it plain text.
String neutralizeFormula(String value) {
  if (value.isEmpty) return value;
  const triggers = {'=', '+', '-', '@', '\t', '\r', '\n'};
  if (!triggers.contains(value[0])) return value;
  // Plain signed numbers such as -3 or +5 are safe and should stay numbers.
  if (RegExp(r'^[+-]?\d+([.,]\d+)?$').hasMatch(value)) return value;
  return "'$value";
}
