import 'package:intl/intl.dart';

class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;

  static bool get _ar => (Intl.defaultLocale ?? '').startsWith('ar');
  static bool get _fr => (Intl.defaultLocale ?? '').startsWith('fr');

  static AppException from(Object error) {
    final text = error.toString();
    if (text.contains('Solde insuffisant')) {
      return AppException(
        _ar
            ? 'الرصيد غير كافٍ.'
            : _fr
            ? 'Solde insuffisant.'
            : 'Insufficient funds.',
      );
    }
    if (text.contains('Plafond de credit')) {
      return AppException(
        _ar
            ? 'تم تجاوز حد الائتمان.'
            : _fr
            ? 'Plafond de crédit dépassé.'
            : 'Credit limit exceeded.',
      );
    }
    if (text.contains('Conversion de devises')) {
      return AppException(
        _ar
            ? 'يجب أن تكون للمحفظتين العملة نفسها. لا يوجد تحويل تلقائي.'
            : _fr
            ? 'Les wallets doivent avoir la même devise. Aucune conversion automatique.'
            : 'Wallets must use the same currency. No automatic conversion.',
      );
    }
    if (text.contains('Montant invalide')) {
      return AppException(
        _ar
            ? 'مبلغ غير صالح.'
            : _fr
            ? 'Montant invalide.'
            : 'Invalid amount.',
      );
    }
    if (text.contains('Wallet')) {
      return AppException(
        _ar
            ? 'المحفظة غير موجودة أو غير مسموح بها.'
            : _fr
            ? 'Wallet introuvable ou non autorisé.'
            : 'Wallet not found or not allowed.',
      );
    }
    if (text.contains('Invalid login credentials')) {
      return AppException(
        _ar
            ? 'البريد أو كلمة المرور غير صحيحة.'
            : _fr
            ? 'Email ou mot de passe incorrect.'
            : 'Incorrect email or password.',
      );
    }
    if (text.toLowerCase().contains('invalid totp code') ||
        text.toLowerCase().contains('mfa_verification_failed')) {
      return AppException(
        _ar
            ? 'الرمز غير صحيح أو انتهت صلاحيته. أدخل الرمز الحالي من تطبيق المصادقة وتأكد من ضبط وقت الهاتف تلقائياً.'
            : _fr
            ? 'Code incorrect ou expiré. Saisissez le code actuel affiché dans votre application d’authentification et vérifiez que l’heure du téléphone est réglée automatiquement.'
            : 'The code is incorrect or expired. Enter the current code from your authenticator app and check that your phone time is set automatically.',
        code: 'invalid_totp_code',
      );
    }
    if (text.toLowerCase().contains('mfa_factor_name_conflict')) {
      return AppException(
        _ar
            ? 'يوجد إعداد تحقق غير مكتمل. ألغِ الإعداد المعلق في Supabase ثم أعد المحاولة.'
            : _fr
            ? 'Une configuration 2FA inachevée existe déjà. Annulez-la dans Supabase Auth, puis réessayez.'
            : 'An unfinished 2FA setup already exists. Remove the pending factor in Supabase Auth, then try again.',
        code: 'mfa_factor_name_conflict',
      );
    }
    if (text.toLowerCase().contains('email not confirmed') ||
        text.toLowerCase().contains('email_not_confirmed')) {
      return AppException(
        _ar
            ? 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.'
            : _fr
            ? 'Confirmez votre adresse email avant de vous connecter.'
            : 'Confirm your email address before signing in.',
      );
    }
    final lower = text.toLowerCase();
    if (lower.contains('user already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user_already_exists') ||
        lower.contains('email_exists')) {
      return AppException(
        _ar
            ? 'يوجد حساب بهذا البريد.'
            : _fr
            ? 'Un compte existe déjà avec cet email.'
            : 'An account already exists with this email.',
        code: 'auth',
      );
    }
    if (lower.contains('password should be at least') ||
        lower.contains('weak_password') ||
        lower.contains('weak password')) {
      return AppException(
        _ar
            ? 'كلمة المرور قصيرة جداً.'
            : _fr
            ? 'Le mot de passe est trop court.'
            : 'The password is too short.',
        code: 'auth',
      );
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email') ||
        lower.contains('email_address_invalid')) {
      return AppException(
        _ar
            ? 'عنوان البريد غير صالح.'
            : _fr
            ? 'Adresse email invalide.'
            : 'The email address is invalid.',
        code: 'auth',
      );
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset')) {
      return AppException(
        _ar
            ? 'الشبكة غير متاحة. حاول مرة أخرى.'
            : _fr
            ? 'Réseau indisponible. Réessayez.'
            : 'Network unavailable. Try again.',
        code: 'network',
      );
    }
    if (lower.contains('error sending confirmation email') ||
        lower.contains('error sending recovery email') ||
        lower.contains('error sending magic link') ||
        lower.contains('smtp') ||
        lower.contains('over_email_send_rate_limit')) {
      return AppException(
        _ar
            ? 'تعذر إرسال رسالة التأكيد. أعد المحاولة بعد قليل.'
            : _fr
            ? 'L’e-mail de confirmation n’a pas pu être envoyé. Réessayez dans quelques minutes.'
            : 'The confirmation email could not be sent. Try again in a few minutes.',
        code: 'email_delivery',
      );
    }
    if (text.contains('429') ||
        text.toLowerCase().contains('rate limit') ||
        text.toLowerCase().contains('too many requests')) {
      return AppException(
        _ar
            ? 'تم إرسال طلبات كثيرة. انتظر قليلاً قبل المحاولة مجدداً.'
            : _fr
            ? 'Trop de demandes. Attendez un peu avant de réessayer.'
            : 'Too many requests. Please wait before trying again.',
        code: 'rate_limited',
      );
    }
    return AppException(text.replaceFirst('Exception: ', ''));
  }
}
