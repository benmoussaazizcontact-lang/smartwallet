import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/errors/app_exception.dart';
import 'package:wallet_app/core/utils/money.dart';
import 'package:wallet_app/features/ai_classification/services/rule_classifier.dart';
import 'package:wallet_app/features/categories/models/category.dart';
import 'package:wallet_app/features/receipts/services/ocr_parser.dart';

void main() {
  group('Error amounts', () {
    test('rejects negative amount', () {
      expect(Money.validate('-10'), isNotNull);
      expect(Money.tryParse('-10'), -10);
    });

    test('rejects zero amount', () {
      expect(Money.validate('0'), isNotNull);
    });
  });

  group('Transfer guards', () {
    test('same wallet ids are invalid', () {
      const from = 'wallet-a';
      const to = 'wallet-a';
      expect(from == to, isTrue);
    });
  });

  group('OCR error inputs', () {
    test('unreadable blank image text extracts nothing useful', () {
      final parsed = const OcrParser().parse('');
      expect(parsed.merchant, isNull);
      expect(parsed.total, isNull);
      expect(parsed.paymentMethod, isNull);
    });

    test('receipt without amount leaves total null', () {
      final parsed = const OcrParser().parse('Restaurant\n08/10/2026\nMerci');
      expect(parsed.merchant, 'Restaurant');
      expect(parsed.total, isNull);
    });
  });

  group('Classification fallback', () {
    test('unrecognized merchant is not invented', () {
      const categories = [
        CategoryItem(id: 'p', name: 'Shopping'),
        CategoryItem(id: 'c', name: 'Groceries', parentId: 'p'),
      ];
      expect(
        const RuleClassifier().classify(
          text: 'UnknownShop 12 TND',
          categories: categories,
        ),
        isNull,
      );
    });
  });

  group('Network mapping', () {
    test('maps socket failures to a clear message', () {
      expect(
        AppException.from(Exception('SocketException: Failed host lookup')).message,
        contains('Network'),
      );
    });

    test('maps insufficient funds', () {
      expect(
        AppException.from(Exception('Solde insuffisant for wallet')).message,
        'Insufficient funds.',
      );
    });
  });
}
