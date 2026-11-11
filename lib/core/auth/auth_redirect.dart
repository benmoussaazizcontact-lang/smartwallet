/// Opens SmartWallet directly from an email confirmation or password reset.
const String authCallbackUrl = 'smartwallet://auth/callback';

/// GoRouter sees `smartwallet://auth/callback` as the path `/callback`.
bool isAuthCallbackLocation(String location) {
  final path = Uri.parse(location).path;
  return path == '/callback' || path == '/auth/callback';
}

bool isRecoveryLink(Uri uri) {
  final fragment = Uri.splitQueryString(uri.fragment);
  final type = uri.queryParameters['type'] ?? fragment['type'];
  return type == 'recovery';
}
