import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/ai_classification/repositories/classification_repository.dart';
import 'package:wallet_app/features/ai_classification/services/rule_classifier.dart';
import 'package:wallet_app/features/ai_classification/services/transaction_classification_service.dart';
import 'package:wallet_app/features/categories/models/category.dart';
import 'package:wallet_app/features/receipts/services/ocr_parser.dart';
import 'package:wallet_app/features/receipts/services/receipt_amounts.dart';

const _catalog = [
  CategoryItem(id: 'food', name: 'Food'),
  CategoryItem(id: 'restaurants', name: 'Restaurants', parentId: 'food'),
  CategoryItem(id: 'shopping', name: 'Shopping'),
  CategoryItem(id: 'groceries', name: 'Groceries', parentId: 'shopping'),
  CategoryItem(id: 'transport', name: 'Transport'),
  CategoryItem(id: 'fuel', name: 'Fuel', parentId: 'transport'),
  CategoryItem(id: 'entertainment', name: 'Entertainment'),
  CategoryItem(id: 'subs', name: 'Subscriptions', parentId: 'entertainment'),
  CategoryItem(id: 'health', name: 'Health'),
  CategoryItem(id: 'pharmacy', name: 'Pharmacy', parentId: 'health'),
  CategoryItem(id: 'income', name: 'Income'),
  CategoryItem(id: 'salary', name: 'Salary', parentId: 'income'),
];

void main() {
  group('OCR parser', () {
    test('extracts the sample restaurant receipt', () {
      const sample = '''
Restaurant
08/10/2026
TOTAL : 48.500 TND
CARD
''';
      final parsed = const OcrParser().parse(sample);
      expect(parsed.merchant, 'Restaurant');
      expect(parsed.date?.year, 2026);
      expect(parsed.date?.month, 10);
      expect(parsed.date?.day, 8);
      expect(parsed.total, 48.5);
      expect(parsed.currency, 'TND');
      expect(parsed.paymentMethod, 'Card');
    });

    test('recognizes ISO dates and cash', () {
      final parsed = const OcrParser().parse('Cafe\n2026-01-15\nAmount 12.000 TND\nCASH');
      expect(parsed.date?.year, 2026);
      expect(parsed.paymentMethod, 'Cash');
      expect(parsed.currency, 'TND');
      expect(parsed.total, 12);
    });

    test('prefers total TTC over sous-total, tax, discount, and change', () {
      const sample = '''
Boulangerie
Sous-total 40,000 TND
TVA 7,600 TND
Remise 2,000 TND
TOTAL TTC 45,600 TND
Montant payé 50,000 TND
Monnaie rendue 4,400 TND
''';
      final parsed = const OcrParser().parse(sample);
      expect(parsed.total, 45.6);
      expect(parsed.currency, 'TND');
      expect(parsed.amountNeedsReview, isFalse);
    });

    test('uses net à payer when it is present', () {
      final parsed = const OcrParser().parse('''
Cafe
Sous-total 40.000 TND
NET À PAYER 48,500 TND
''');
      expect(parsed.total, 48.5);
    });

    test('english subtotal does not replace the final total', () {
      final parsed = const OcrParser().parse('''
Market
SUBTOTAL 10.00 EUR
TAX 2.50 EUR
TOTAL 12.50 EUR
''');
      expect(parsed.total, 12.5);
      expect(parsed.currency, 'EUR');
    });

    test('reads grouped Tunisian millimes and euro cents', () {
      expect(
        const OcrParser().parse('Station\nTOTAL 1 250,000 TND').total,
        1250,
      );
      expect(
        const OcrParser().parse('Shop\nTOTAL 48,50 EUR').total,
        48.5,
      );
    });

    test('a parking ticket keeps the place name, the millimes, and the receipt number', () {
      const ticket = '''
N° 00011027
Prix : 3.000 D
Parking Automobile Non Gardé
Parking S.ZAGHLOUL
''';
      final parsed = const OcrParser().parse(ticket);
      expect(parsed.merchant, 'Parking S.ZAGHLOUL');
      expect(parsed.merchant, isNot(contains('00011027')));
      expect(parsed.receiptNumber, '00011027');
      expect(parsed.total, 3);
      expect(parsed.currency, 'TND');
      expect(parsed.amountNeedsReview, isFalse);
      expect(parsed.paymentMethod, isNull);
      expect(parsed.items, isEmpty);
      expect(formatReceiptAmount(parsed.total!, parsed.currency), '3.000');

      const rules = RuleClassifier();
      final withoutParking = rules.classify(text: ticket, categories: _catalog);
      expect(withoutParking?.categoryName, 'Transport');
      expect(withoutParking?.subcategoryName, isNull);
      expect(withoutParking?.reason, contains('Transport'));

      final withParking = rules.classify(
        text: ticket,
        categories: const [
          ..._catalog,
          CategoryItem(id: 'parking', name: 'Parking', parentId: 'transport'),
        ],
      );
      expect(withParking?.label, 'Transport / Parking');
    });

    test('asks for a manual amount when only a subtotal exists', () {
      final parsed = const OcrParser().parse('Shop\nSous-total 40,000 TND');
      expect(parsed.total, isNull);
      expect(parsed.amountNeedsReview, isTrue);
    });
  });

  group('Local classification', () {
    const rules = RuleClassifier();

    test('Carrefour 85 TND → Shopping / Groceries at 95%', () {
      final result = rules.classify(text: 'Carrefour 85 TND', categories: _catalog);
      expect(result?.label, 'Shopping / Groceries');
      expect(result?.confidencePercent, 95);
    });

    test('Restaurant 48.500 TND → Food / Restaurants', () {
      final result = rules.classify(
        text: 'Restaurant 48.500 TND',
        categories: _catalog,
      );
      expect(result?.label, 'Food / Restaurants');
      expect(result!.confidence, greaterThanOrEqualTo(0.95));
    });

    test('Shell 120 TND → Transport / Fuel', () {
      final result = rules.classify(text: 'Shell 120 TND', categories: _catalog);
      expect(result?.label, 'Transport / Fuel');
    });

    test('Netflix 25 TND → Entertainment / Subscriptions', () {
      final result = rules.classify(text: 'Netflix 25 TND', categories: _catalog);
      expect(result?.label, 'Entertainment / Subscriptions');
    });

    test('Pharmacy 32 TND → Health / Pharmacy', () {
      final result = rules.classify(text: 'Pharmacy 32 TND', categories: _catalog);
      expect(result?.label, 'Health / Pharmacy');
    });

    test('Salary 2500 TND → Income / Salary', () {
      final result = rules.classify(text: 'Salary 2500 TND', categories: _catalog);
      expect(result?.label, 'Income / Salary');
    });

    test('unknown merchant is not invented', () {
      expect(
        rules.classify(text: 'zzzz unknown merchant', categories: _catalog),
        isNull,
      );
    });
  });

  group('User corrections', () {
    test('previous correction beats keyword rules', () {
      final result = TransactionClassificationService.classifyLocal(
        text: 'Carrefour 10',
        merchant: 'Carrefour',
        categories: _catalog,
        corrections: const [
          MerchantCorrection(merchantKey: 'carrefour', categoryId: 'fuel'),
        ],
      );
      expect(result?.chosenCategoryId, 'fuel');
      expect(result?.confidencePercent, 99);
    });
  });
}
