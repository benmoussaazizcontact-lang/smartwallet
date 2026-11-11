/// A cached value may be shown only when it was loaded for the user who is
/// signed in now. A missing session or a different account hides it.
bool belongsToActiveUser({
  required String? loadedFor,
  required String? active,
}) {
  return loadedFor != null && loadedFor.isNotEmpty && loadedFor == active;
}
