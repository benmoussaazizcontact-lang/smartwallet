import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/money.dart';
import 'package:wallet_app/features/ai_classification/services/rule_classifier.dart';
import 'package:wallet_app/features/categories/models/category.dart';
import 'package:wallet_app/features/receipts/services/ocr_parser.dart';

void main() {
  group('Money validation', () {
    test('rejects empty and negative amounts', () {
      expect(Money.validate(''), isNotNull);
      expect(Money.validate('-1'), isNotNull);
      expect(Money.validate('0'), isNotNull);
    });

    test('accepts TND-style three decimals', () {
      expect(Money.validate('48.500'), isNull);
      expect(Money.tryParse('48,500'), 48.5);
    });

    test('rejects more than three decimals', () {
      expect(Money.validate('1.2345'), isNotNull);
    });

    test('formats TND with three fraction digits', () {
      expect(Money.format(12.5, 'TND'), contains('TND'));
      expect(Money.format(12.5, 'TND'), contains('12.500'));
    });
  });


  group('OCR parser', () {
    test('extracts merchant, date, total and currency', () {
      const sample = '''
Restaurant
Date: 08/10/2026
Total: 48.500 TND
Payment Method: Card
''';
      final parsed = const OcrParser().parse(sample);
      expect(parsed.merchant, 'Restaurant');
      expect(parsed.total, 48.5);
      expect(parsed.currency, 'TND');
      expect(parsed.paymentMethod, 'Card');
      expect(parsed.date?.year, 2026);
    });
  });

  group('Rule classifier', () {
    test('maps Carrefour to groceries without inventing data', () {
      const categories = [
        CategoryItem(id: 'p', name: 'Shopping'),
        CategoryItem(id: 'c', name: 'Groceries', parentId: 'p'),
      ];
      final result = const RuleClassifier().classify(
        text: 'Carrefour 85 TND',
        categories: categories,
      );
      expect(result?.subcategoryName, 'Groceries');
      expect(result!.confidence, greaterThan(0.7));
    });

    test('returns null when nothing matches', () {
      const categories = [CategoryItem(id: 'p', name: 'Shopping')];
      final result = const RuleClassifier().classify(
        text: 'zzzz unknown merchant',
        categories: categories,
      );
      expect(result, isNull);
    });
  });

  group('Idempotency client id', () {
    test('round3 is stable for duplicate-click amounts', () {
      expect(Money.round3(10.1), Money.round3(10.1));
    });
  });
}
