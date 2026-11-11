/// The typed word must match exactly after trimming. Case is ignored so a
/// phone keyboard does not reject a correct confirmation.
bool accountDeletionConfirmed(String typed, String expected) {
  final given = typed.trim().toUpperCase();
  final required = expected.trim().toUpperCase();
  return given.isNotEmpty && given == required;
}
