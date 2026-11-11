import '../../intelligence/domain/advanced_finance.dart';
import 'spend_rules.dart';

enum AssistantIntent {
  spendingTotal,
  spendingByCategory,
  incomeTotal,
  walletBalance,
  budgetStatus,
  spendingComparison,
  topExpenseCategories,
  savingAdvice,
  savingGoalPlan,
  affordability,
  subscriptionAnalysis,
  anomalyExplanation,
  cashflowForecast,
  goalProgress,
  investmentSummary,
  clarify,
  unknown,
}

class AssistantWallet {
  const AssistantWallet({
    required this.name,
    required this.currency,
    required this.balance,
    required this.type,
  });

  final String name;
  final String currency;
  final num balance;
  final String type;
}

class AssistantGoalView {
  const AssistantGoalView({
    required this.name,
    required this.target,
    required this.saved,
    required this.currency,
  });

  final String name;
  final num target;
  final num saved;
  final String currency;

  num get gap => target - saved < 0 ? 0 : target - saved;
}

class AssistantBudgetView {
  const AssistantBudgetView({
    required this.name,
    required this.limit,
    required this.spent,
    required this.currency,
    required this.period,
    this.categoryName,
  });

  final String name;
  final num limit;
  final num spent;
  final String currency;
  final String period;
  final String? categoryName;
}

class AssistantAssetView {
  const AssistantAssetView({
    required this.label,
    required this.currency,
    required this.manualPrice,
    this.gain,
    this.marketValue,
  });

  final String label;
  final String currency;
  final bool manualPrice;
  final num? gain;
  final num? marketValue;
}

class AssistantLedger {
  const AssistantLedger({
    required this.events,
    required this.currency,
    this.loaded = true,
    this.hold,
    this.wallets = const [],
    this.walletsReady = true,
    this.goals = const [],
    this.budgets = const [],
    this.assets = const [],
    this.aggregateSpent,
    this.aggregateIncome,
    this.aggregateTopCategory,
    this.aggregateTopAmount,
    this.aggregateThisWeek,
    this.aggregateLastWeek,
    this.weekComparable = false,
    this.aggregateOnly = false,
  });

  final List<SpendEvent> events;
  final String currency;
  final bool loaded;
  final String? hold;
  final List<AssistantWallet> wallets;
  final bool walletsReady;
  final List<AssistantGoalView> goals;
  final List<AssistantBudgetView> budgets;
  final List<AssistantAssetView> assets;
  final num? aggregateSpent;
  final num? aggregateIncome;
  final String? aggregateTopCategory;
  final num? aggregateTopAmount;
  final num? aggregateThisWeek;
  final num? aggregateLastWeek;
  final bool weekComparable;
  final bool aggregateOnly;

  bool get hasEvents => events.isNotEmpty;
}

class TalkContext {
  const TalkContext({
    this.intent,
    this.categoryToken,
    this.categories = const [],
    this.period = 'month',
    this.amount,
    this.months,
    this.currency,
  });

  final AssistantIntent? intent;
  final String? categoryToken;
  final List<String> categories;
  final String period;
  final num? amount;
  final int? months;
  final String? currency;

  TalkContext copy({
    AssistantIntent? intent,
    String? categoryToken,
    List<String>? categories,
    String? period,
    num? amount,
    int? months,
    String? currency,
    bool clearCategories = false,
  }) {
    return TalkContext(
      intent: intent ?? this.intent,
      categoryToken: categoryToken ?? this.categoryToken,
      categories: clearCategories ? const [] : (categories ?? this.categories),
      period: period ?? this.period,
      amount: amount ?? this.amount,
      months: months ?? this.months,
      currency: currency ?? this.currency,
    );
  }
}

class SavingCut {
  const SavingCut({required this.category, required this.observed, required this.reduction});

  final String category;
  final num observed;
  final num reduction;
}

class AssistantTurn {
  const AssistantTurn({
    required this.answered,
    required this.text,
    required this.intent,
    required this.context,
    this.simulation = false,
    this.confidence = 0,
    this.cuts = const [],
  });

  final bool answered;
  final String text;
  final AssistantIntent intent;
  final TalkContext context;
  final bool simulation;
  final double confidence;
  final List<SavingCut> cuts;
}

class Understanding {
  const Understanding({
    required this.intent,
    required this.confidence,
    this.categoryToken,
    this.period = 'month',
    this.amount,
    this.months,
    this.currency,
    this.followUp = false,
    this.why = false,
    this.ambiguous = false,
  });

  final AssistantIntent intent;
  final double confidence;
  final String? categoryToken;
  final String period;
  final num? amount;
  final int? months;
  final String? currency;
  final bool followUp;
  final bool why;
  final bool ambiguous;
}

const _broadFood = {
  'food',
  'nourriture',
  'alimentation',
  'makla',
  'makan',
  'akl',
  'makanat',
  'طعام',
  'أكل',
  'ماكلة',
};

const _groups = <String, Set<String>>{
  'food': {
    'food',
    'nourriture',
    'alimentation',
    'grocery',
    'groceries',
    'courses',
    'course',
    'supermarche',
    'makla',
    'makan',
    'akl',
    'restaurant',
    'resto',
    'restaurants',
    'cafe',
    'coffee',
    'طعام',
    'أكل',
    'ماكلة',
    'ماكله',
    'مطعم',
  },
  'restaurant': {'restaurant', 'resto', 'restaurants', 'cafe', 'coffee', 'مطعم'},
  'groceries': {'grocery', 'groceries', 'courses', 'course', 'supermarche', 'epicerie', 'alimentation'},
  'transport': {
    'transport',
    'taxi',
    'bus',
    'metro',
    'carburant',
    'essence',
    'fuel',
    'karhba',
    'transportation',
    'نقل',
    'مواصلات',
    'تاكسي',
  },
  'leisure': {'loisir', 'loisirs', 'leisure', 'sortie', 'sorties', 'cinema', 'divertissement'},
  'shopping': {'shopping', 'achat', 'achats', 'shop'},
  'housing': {'loyer', 'rent', 'logement', 'housing', 'habitation'},
  'health': {'sante', 'health', 'pharmacie', 'medecin'},
  'bills': {'facture', 'factures', 'bill', 'bills', 'electricite', 'eau', 'internet'},
  'education': {'education', 'ecole', 'school', 'universite'},
};

const _essential = {'housing', 'health', 'bills', 'education'};

String foldQuestion(String raw) {
  var text = raw.toLowerCase().trim();
  text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  const arabicLetters = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي'};
  arabicLetters.forEach((from, to) => text = text.replaceAll(from, to));
  const digits = {'٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9', '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4', '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9'};
  digits.forEach((from, to) => text = text.replaceAll(from, to));
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };
  accents.forEach((from, to) => text = text.replaceAll(from, to));
  text = text.replaceAll(RegExp("[’'`]"), ' ').replaceAll(RegExp(r'[?!.,;:()؟،]+'), ' ');
  final protected = <String>[];
  text = text.replaceAllMapped(RegExp(r'(^|[^0-9a-z\u0600-\u06FF])(\d+(?:[.,]\d{1,3})?)(?=$|[^0-9a-z\u0600-\u06FF])'), (match) {
    protected.add(match.group(2)!);
    return '${match.group(1)}§${protected.length - 1}§';
  });
  text = text.split(RegExp(r'\s+')).map(_foldSpokenToken).where((token) => token.isNotEmpty).join(' ');
  const phrases = <List<String>>[
    ['semaine hethi', 'cette semaine'],
    ['semaine hedhi', 'cette semaine'],
    ['semaine hdhi', 'cette semaine'],
    ['semaine hadhi', 'cette semaine'],
    ['semaine eli fetet', 'semaine derniere'],
    ['semaine eli fatet', 'semaine derniere'],
    ['semaine eli fet', 'semaine derniere'],
    ['mois hedha', 'ce mois'],
    ['mois hetha', 'ce mois'],
    ['mois hadha', 'ce mois'],
    ['mois hedhi', 'ce mois'],
    ['el mois hedha', 'ce mois'],
    ['mois eli fet', 'mois dernier'],
    ['mois eli fat', 'mois dernier'],
    ['annee hedha', 'cette annee'],
    ['annee eli fet', 'annee derniere'],
    ['قداش', 'كم'],
    ['شحال', 'كم'],
    ['صرفت', 'مصروف'],
    ['انفقت', 'مصروف'],
    ['أنفقت', 'مصروف'],
    ['فلوس', 'رصيد'],
    ['مال', 'رصيد'],
    ['الجمعه هاذي', 'هذا الاسبوع'],
    ['الجمعه هذه', 'هذا الاسبوع'],
    ['ماكله', 'ماكلة'],
    ['الشهر هذا', 'هذا الشهر'],
    ['الباقي', 'رصيد'],
    ['باقيلي', 'رصيد'],
    ['نوفر', 'وفر'],
    ['نجمع', 'وفر'],
    ['comment du depense', 'combien depense'],
    ['comment de depense', 'combien depense'],
    ['ch7al', 'combien'],
    ['chhal', 'combien'],
    ['9adeh', 'combien'],
    ['kadesh', 'combien'],
    ['qadeh', 'combien'],
    ['sarraft', 'depense'],
    ['sareft', 'depense'],
    ['sarft', 'depense'],
    ['khrejt', 'depense'],
    ['kharajt', 'depense'],
    ['fel ', 'en '],
    ['fl ', 'en '],
    ['makla', 'nourriture'],
    ['3lech', 'pourquoi'],
    ['3lah', 'pourquoi'],
    ['combient', 'combien'],
    ['conbien', 'combien'],
    ['comb1en', 'combien'],
    ['depanse', 'depense'],
    ['depensee', 'depense'],
    ['depenser', 'depense'],
    ['depenses', 'depense'],
    ['depense', 'depense'],
    ['ce moi', 'ce mois'],
    ['se mois', 'ce mois'],
    ['ce mois ci', 'ce mois'],
    ['mois dernier', 'mois dernier'],
    ['semaine derniere', 'semaine derniere'],
    ['porquoi', 'pourquoi'],
    ['pourkoi', 'pourquoi'],
    ['pk ', 'pourquoi '],
    ['pq ', 'pourquoi '],
    ['economiser', 'economiser'],
    ['economise', 'economiser'],
    ['epargner', 'economiser'],
    ['epargne', 'economiser'],
    ['reduire', 'reduire'],
    ['categrie', 'categorie'],
    ['categorie', 'categorie'],
    ['telefone', 'telephone'],
    ['telephon', 'telephone'],
  ];
  for (final pair in phrases) {
    text = text.replaceAll(pair[0], pair[1]);
  }
  for (var i = 0; i < protected.length; i++) {
    text = text.replaceAll('§$i§', protected[i]);
  }
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.endsWith(' moi')) text = '${text.substring(0, text.length - 4)} mois';
  return text;
}

String _foldSpokenToken(String token) {
  if (token.startsWith('§')) return token;
  var spoken = token.replaceAllMapped(RegExp(r'(.)\1{2,}'), (match) => '${match.group(1)}${match.group(1)}');
  const known = {
    'kadech': 'combien',
    'kadesh': 'combien',
    '9adech': 'combien',
    '9adeh': 'combien',
    'qadech': 'combien',
    'qadeh': 'combien',
    'ch7al': 'combien',
    'chhal': 'combien',
    'chahal': 'combien',
    '3andi': 'avoir',
    '3ndi': 'avoir',
    'andi': 'avoir',
    'sraft': 'depense',
    'sarraft': 'depense',
    'srafet': 'depense',
    'sareft': 'depense',
    'sarft': 'depense',
    'joma': 'semaine',
    'jem3a': 'semaine',
    'jom3a': 'semaine',
    'jma': 'semaine',
    'chhar': 'mois',
    'chahr': 'mois',
    'hethi': 'hethi',
    'hedhi': 'hedhi',
    'hdhi': 'hdhi',
    'hedha': 'hedha',
    'hetha': 'hedha',
    'lbare7': 'hier',
    'lbareh': 'hier',
    'lyoum': 'aujourdhui',
    'flous': 'solde',
    'flouss': 'solde',
    'flousss': 'solde',
    'flos': 'solde',
    'ba9ili': 'reste',
    'ba9i': 'reste',
    'baqi': 'reste',
    'mte3i': '',
    'mte3': '',
    'makla': 'nourriture',
    'mekla': 'nourriture',
    'nwafar': 'economiser',
    'nlem': 'economiser',
    'kifech': 'comment',
    'kifeh': 'comment',
    '5dhit': 'salaire',
    'dkhalt': 'revenu',
    'dakhli': 'revenu',
    'reb7t': 'gain',
    '5sert': 'perte',
    'far9': 'comparaison',
    'farq': 'comparaison',
    '9bal': 'dernier',
    'qbal': 'dernier',
    '3am': 'annee',
    'barcha': 'plus',
    'resto': 'restaurant',
    'essence': 'essence',
  };
  if (known.containsKey(spoken)) return known[spoken]!;
  for (final prefix in ['fel', '3al', 'fl']) {
    if (spoken.startsWith(prefix) && spoken.length > prefix.length + 2) {
      return 'en ${_foldSpokenToken(spoken.substring(prefix.length))}';
    }
  }
  if (RegExp(r'\d').hasMatch(spoken) && RegExp(r'[a-z]').hasMatch(spoken)) {
    spoken = spoken
        .replaceAll('5', 'kh')
        .replaceAll('7', 'h')
        .replaceAll('9', 'q')
        .replaceAll('3', 'a')
        .replaceAll('2', 'a')
        .replaceAll('8', 'gh');
    if (known.containsKey(spoken)) return known[spoken]!;
  }
  return spoken;
}

int _distance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      final insert = current[j] + 1;
      final remove = previous[j + 1] + 1;
      final replace = previous[j] + cost;
      var best = insert < remove ? insert : remove;
      if (replace < best) best = replace;
      current[j + 1] = best;
    }
    previous = current;
  }
  return previous[b.length];
}

bool _has(String text, List<String> words) {
  for (final word in words) {
    if (word.runes.any((rune) => rune > 127)) {
      if (text.contains(word)) return true;
      continue;
    }
    if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text)) return true;
    for (final token in text.split(' ')) {
      if (token.length >= 5 && word.length >= 5 && _distance(token, word) <= 1) return true;
    }
  }
  return false;
}

String? _categoryToken(String text) {
  final tokens = text.split(' ').where((token) => token.isNotEmpty).toList();
  String? best;
  var bestScore = 0;
  for (final group in _groups.values) {
    for (final word in group) {
      if (word.runes.any((rune) => rune > 127)) {
        if (text.contains(word) && word.length > bestScore) {
          best = word;
          bestScore = word.length;
        }
        continue;
      }
      if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text) && word.length > bestScore) {
        best = word;
        bestScore = word.length;
      }
    }
  }
  for (final token in tokens) {
    if (token.length < 4) continue;
    for (final group in _groups.values) {
      for (final word in group) {
        if (word.runes.any((rune) => rune > 127)) continue;
        if (_distance(token, word) <= 1 && word.length >= bestScore) {
          best = word;
          bestScore = word.length;
        }
      }
    }
  }
  return best;
}

String? _periodOf(String text) {
  if (_has(text, ['annee derniere', 'last year', 'العام الي فات', 'العام اللي فات'])) return 'last_year';
  if (_has(text, ['cette annee', 'this year', 'العام هذا', 'هاد العام'])) return 'year';
  if (_has(text, ['semaine derniere', 'last week', 'الاسبوع الماضي', 'الأسبوع الماضي'])) return 'last_week';
  if (_has(text, ['cette semaine', 'this week', 'هذا الاسبوع', 'هذا الأسبوع', 'الجمعة هاذي', 'الجمعة هذه'])) return 'week';
  if (_has(text, ['mois dernier', 'last month', 'الشهر الماضي', 'الشهر اللي فات'])) return 'last_month';
  if (_has(text, ['hier', 'yesterday', 'البارح', 'امس', 'أمس'])) return 'yesterday';
  if (_has(text, ['aujourdhui', 'today', 'اليوم'])) return 'today';
  if (_has(text, ['ce mois', 'this month', 'هذا الشهر'])) return 'month';
  return null;
}

num? _amountOf(String text) {
  final match = RegExp(r'(\d+(?:[.,]\d{1,3})?)').firstMatch(text);
  if (match == null) return null;
  return num.tryParse(match.group(1)!.replaceAll(',', '.'));
}

int? _monthsOf(String text) {
  final match = RegExp(r'(\d+)\s*(mois|months|شهر)').firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String? _currencyOf(String text) {
  if (RegExp(r'\b(eur|euro|euros)\b|€').hasMatch(text)) return 'EUR';
  if (RegExp(r'\b(usd|dollar|dollars)\b|\$').hasMatch(text)) return 'USD';
  if (RegExp(r'\b(tnd|dt|dinar|dinars)\b|دينار').hasMatch(text)) return 'TND';
  return null;
}

bool _followUp(String text) {
  if (RegExp(r'^(et|and|w|wel|ou|و|وماذا)\b').hasMatch(text)) return true;
  if (RegExp(r'^(pourquoi|why|comment ca)\b').hasMatch(text) && text.split(' ').length <= 5) return true;
  final words = text.split(' ').where((word) => word.isNotEmpty).length;
  if (words <= 5 && _periodOf(text) != null && !_has(text, ['depense', 'solde', 'revenu', 'budget', 'objectif'])) {
    return true;
  }
  return false;
}

Understanding understandQuestion(String raw) {
  final text = foldQuestion(raw);
  final category = _categoryToken(text);
  final period = _periodOf(text);
  final amount = _amountOf(text);
  final months = _monthsOf(text);
  final currency = _currencyOf(text);
  final follow = _followUp(text);
  final spend = _has(text, ['depense', 'spent', 'spend', 'spending', 'spen', 'cout', 'coute', 'انفقت', 'مصروف', 'صرفت']);
  final income = _has(text, ['revenu', 'revenus', 'salaire', 'income', 'gagne', 'earned', 'دخل', 'راتب']);
  final balance = _has(text, ['solde', 'reste', 'restant', 'compte', 'balance', 'portefeuille', 'wallet', 'رصيد', 'حساب']);
  final budget = _has(text, ['budget', 'ميزانية']);
  final compare = _has(text, ['dernier', 'compar', 'comparaison', 'plus que', 'moins que', 'depense plus', 'versus', 'vs', 'augment', 'increase', 'baisse', 'farq']);
  final top = _has(text, ['plus grosse', 'plus cher', 'coute le plus', 'coute le plus', 'largest', 'biggest', 'top', 'اكبر', 'أكبر']);
  final save = _has(text, ['economiser', 'epargn', 'save', 'saving', 'وفر']);
  final reduce = _has(text, ['reduire', 'reduir', 'baisser', 'cut', 'too much', 'trop', 'تخفيض']);
  final why = _has(text, ['pourquoi', 'why', 'pk']);
  final buy = _has(text, ['acheter', 'achat', 'afford', 'buy', 'telephone', 'phone', 'شراء']);
  final goal = _has(text, ['objectif', 'goal', 'هدف']);
  final invest = _has(text, ['invest', 'investissement', 'investissements', 'placement', 'gain', 'gains', 'perte', 'استثمار']);
  final sub = _has(text, ['abonnement', 'subscription', 'netflix', 'spotify', 'اشتراك']);
  final anomaly = text.contains('anomal') || _has(text, ['inhabituel', 'etrange', 'unusual', 'شاذ']);
  final forecast = _has(text, ['prevision', 'forecast', 'dans 7', 'dans 30', 'dans 90', 'jours', 'توقع']);
  final scores = <AssistantIntent, double>{};
  void add(AssistantIntent intent, double score) => scores[intent] = (scores[intent] ?? 0) + score;

  if (follow && text.split(' ').length <= 6) add(AssistantIntent.unknown, 0.2);
  if (spend && category != null) add(AssistantIntent.spendingByCategory, 4);
  if (category != null && !income && !balance && !save && !buy) add(AssistantIntent.spendingByCategory, 2.8);
  if ((period == 'last_week' || period == 'last_month') && category == null && !spend) {
    add(AssistantIntent.spendingComparison, 2.6);
  }
  if (spend && category == null && !compare && !why) add(AssistantIntent.spendingTotal, 3);
  if (compare && (spend || category != null || _has(text, ['depense', 'augment']))) add(AssistantIntent.spendingComparison, 3.4);
  if (top || (_has(text, ['categorie', 'category', 'فئة']) && _has(text, ['plus', 'coute', 'largest', 'biggest']))) {
    add(AssistantIntent.topExpenseCategories, 3.6);
  }
  if (income && !spend) add(AssistantIntent.incomeTotal, 3.5);
  if (balance && !spend && !save && !income && !goal && !budget) add(AssistantIntent.walletBalance, 3.5);
  if (budget && !save) add(AssistantIntent.budgetStatus, 3.2);
  if ((save || reduce) && amount != null && (months != null || _has(text, ['mois', 'month']))) {
    add(AssistantIntent.savingGoalPlan, 4.4);
  } else if (save && amount != null) {
    add(AssistantIntent.savingGoalPlan, 4);
  }
  if ((save || reduce || (why && _has(text, ['trop', 'too much']))) && amount == null) {
    add(AssistantIntent.savingAdvice, 3.3);
  }
  if (buy && amount != null) add(AssistantIntent.affordability, 4.2);
  if (sub) add(AssistantIntent.subscriptionAnalysis, 3.6);
  if (anomaly) add(AssistantIntent.anomalyExplanation, 3.6);
  if (forecast && _has(text, ['prevision', 'forecast', 'jours', 'cash', 'tresorerie', 'توقع'])) {
    add(AssistantIntent.cashflowForecast, 3.4);
  }
  if (goal && amount == null) add(AssistantIntent.goalProgress, 3.3);
  if (invest && !balance) add(AssistantIntent.investmentSummary, 3.4);
  if (why && compare) add(AssistantIntent.spendingComparison, 1);
  if (follow && why) add(AssistantIntent.anomalyExplanation, 1.2);

  if (scores.isEmpty) {
    return Understanding(
      intent: AssistantIntent.unknown,
      confidence: follow ? 0.4 : 0.1,
      categoryToken: category,
      period: period ?? 'month',
      amount: amount,
      months: months,
      currency: currency,
      followUp: follow,
      why: why,
    );
  }
  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final best = ranked.first;
  final second = ranked.length > 1 ? ranked[1].value : 0.0;
  return Understanding(
    intent: best.key,
    confidence: best.value,
    categoryToken: category,
    period: period ?? 'month',
    amount: amount,
    months: months,
    currency: currency,
    followUp: follow,
    why: why,
    ambiguous: best.value - second < 0.15 && second >= 3,
  );
}

String _replyLanguage(String language, String raw) {
  if (RegExp(r'[\u0600-\u06FF]').hasMatch(raw)) return 'ar';
  final latin = raw.toLowerCase();
  if (RegExp(r'\b(kadech|9adech|3andi|3ndi|sraft|sarraft|flouss|flous|chhar|jem3a|joma|ba9ili|mte3i|ch7al|chhal|lbare7|lyoum|nwafar|nheb|kifech)\b').hasMatch(latin) ||
      RegExp(r'(^|[^0-9])[37925][a-z]|[a-z][379]([^0-9]|$)').hasMatch(latin)) {
    return 'tn';
  }
  if (language.startsWith('ar')) return 'ar';
  if (language.startsWith('en')) return 'en';
  return 'fr';
}

String _money(num value, String currency) => '${value.toStringAsFixed(3)} $currency';

num _round3(num value) => (value * 1000).round() / 1000;

PeriodWindow _window(String period, DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  switch (period) {
    case 'today':
      return PeriodWindow(day, day.add(const Duration(days: 1)));
    case 'yesterday':
      return PeriodWindow(day.subtract(const Duration(days: 1)), day);
    case 'week':
      return periodWindow('weekly', now);
    case 'last_week':
      return previousWindow('weekly', now);
    case 'last_month':
      return previousWindow('monthly', now);
    case 'year':
      return PeriodWindow(DateTime(now.year), DateTime(now.year + 1));
    case 'last_year':
      return PeriodWindow(DateTime(now.year - 1), DateTime(now.year));
    default:
      return periodWindow('monthly', now);
  }
}

String _periodLabel(String period, PeriodWindow window, String language) {
  final start = '${window.start.day}/${window.start.month}/${window.start.year}';
  final end = window.end.subtract(const Duration(days: 1));
  final until = '${end.day}/${end.month}/${end.year}';
  final range = '$start – $until';
  if (language == 'tn') {
    final name = switch (period) {
      'today' => 'Lyoum',
      'yesterday' => 'Lbareh',
      'week' => 'Jem3a hedhi',
      'last_week' => 'Jem3a eli fetet',
      'last_month' => 'Chhar eli fet',
      'year' => '3am hedha',
      'last_year' => '3am eli fet',
      _ => 'Chhar hedha',
    };
    return '$name ($range)';
  }
  if (language == 'ar') {
    return switch (period) {
      'today' => 'اليوم ($range)',
      'yesterday' => 'البارح ($range)',
      'week' => 'هذا الأسبوع ($range)',
      'last_week' => 'الأسبوع الماضي ($range)',
      'last_month' => 'الشهر الماضي ($range)',
      'year' => 'هذه السنة ($range)',
      'last_year' => 'السنة الماضية ($range)',
      _ => 'هذا الشهر ($range)',
    };
  }
  if (language == 'en') {
    return switch (period) {
      'today' => 'today ($range)',
      'yesterday' => 'yesterday ($range)',
      'week' => 'this week ($range)',
      'last_week' => 'last week ($range)',
      'last_month' => 'last month ($range)',
      'year' => 'this year ($range)',
      'last_year' => 'last year ($range)',
      _ => 'this month ($range)',
    };
  }
  return switch (period) {
    'today' => 'aujourd’hui ($range)',
    'yesterday' => 'hier ($range)',
    'week' => 'cette semaine ($range)',
    'last_week' => 'la semaine dernière ($range)',
    'last_month' => 'le mois dernier ($range)',
    'year' => 'cette année ($range)',
    'last_year' => 'l’année dernière ($range)',
    _ => 'ce mois-ci ($range)',
  };
}

Map<String, num> _totals(Iterable<SpendEvent> events, PeriodWindow window, String currency, {bool income = false}) {
  final totals = <String, num>{};
  for (final event in events) {
    final include = income ? countsAsIncome(event) : countsAsSpending(event);
    if (!include || event.currency != currency) continue;
    if (!window.contains(event.date.toLocal())) continue;
    final key = (event.categoryName ?? event.categoryId ?? 'other').trim();
    totals[key] = _round3((totals[key] ?? 0) + event.amount);
  }
  for (final entry in totals.entries) {
    totals[entry.key] = _round3(entry.value);
  }
  return totals;
}

num _totalOf(Map<String, num> totals) => _round3(totals.values.fold<num>(0, (sum, value) => sum + value));

String _foldName(String value) => foldQuestion(value);

String? _groupForName(String name) {
  final folded = _foldName(name);
  final tokens = folded.split(' ');
  for (final entry in _groups.entries) {
    if (entry.value.contains(folded)) return entry.key;
    for (final token in tokens) {
      if (entry.value.contains(token)) return entry.key;
    }
  }
  return null;
}

class _CategoryMatch {
  const _CategoryMatch.one(this.names) : clarify = false;
  const _CategoryMatch.many(this.names) : clarify = true;
  const _CategoryMatch.none()
      : names = const [],
        clarify = false;

  final List<String> names;
  final bool clarify;
}

_CategoryMatch _matchCategories(String? token, Map<String, num> totals) {
  if (token == null) return const _CategoryMatch.none();
  final names = totals.keys.toList();
  final exact = names.where((name) => _foldName(name) == token).toList();
  if (exact.length == 1) return _CategoryMatch.one(exact);
  if (_broadFood.contains(token)) {
    final food = names.where((name) {
      final group = _groupForName(name);
      return group == 'food' || group == 'restaurant' || group == 'groceries';
    }).toList();
    if (food.length > 1) return _CategoryMatch.many(food);
    if (food.length == 1) return _CategoryMatch.one(food);
  }
  final wanted = <String>{};
  for (final entry in _groups.entries) {
    if (entry.value.contains(token)) wanted.add(entry.key);
  }
  final hits = names.where((name) {
    final group = _groupForName(name);
    if (group != null && wanted.contains(group)) return true;
    final folded = _foldName(name);
    return folded.contains(token) || token.contains(folded);
  }).toList();
  if (hits.length > 1 && _broadFood.contains(token)) return _CategoryMatch.many(hits);
  if (hits.length == 1) return _CategoryMatch.one(hits);
  if (hits.length > 1) {
    final specific = hits.where((name) => _foldName(name).contains(token) || _groupForName(name) == token).toList();
    if (specific.length == 1) return _CategoryMatch.one(specific);
    return _CategoryMatch.many(hits);
  }
  String? fuzzy;
  var best = 99;
  for (final name in names) {
    final distance = _distance(_foldName(name), token);
    if (distance < best && distance <= 2) {
      best = distance;
      fuzzy = name;
    }
  }
  if (fuzzy != null) return _CategoryMatch.one([fuzzy]);
  return const _CategoryMatch.none();
}

String _loading(String language) => switch (language) {
      'ar' => 'السجلات ما زالت تُحمَّل.',
      'en' => 'Your records are still loading.',
      'tn' => 'Mazel el enregistrements yet7amlou.',
      _ => 'Les enregistrements sont encore en cours de chargement.',
    };

String _none(String language, String periodLabel) => switch (language) {
      'ar' => 'لا توجد مصروفات مسجلة $periodLabel. المجموع 0.000 بعد تحميل السجلات. التحويلات الداخلية غير محسوبة.',
      'en' => 'There are no expenses recorded for $periodLabel. The total is 0.000 after the records loaded. Internal transfers are excluded.',
      'tn' => 'Mafammach depenses $periodLabel. El total 0.000. El virements mouch mahsounin.',
      _ => 'Il n’y a pas encore de dépenses $periodLabel. Le total est 0.000 après chargement des enregistrements. Les transferts internes sont exclus.',
    };

AssistantTurn _turn({
  required bool answered,
  required String text,
  required AssistantIntent intent,
  required TalkContext context,
  bool simulation = false,
  double confidence = 1,
  List<SavingCut> cuts = const [],
}) {
  return AssistantTurn(
    answered: answered,
    text: text,
    intent: intent,
    context: context,
    simulation: simulation,
    confidence: confidence,
    cuts: cuts,
  );
}

List<SavingCut> planCuts(Map<String, num> flexible, num target) {
  final entries = flexible.entries.where((entry) => entry.value > 0.009).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty || target <= 0) return const [];
  final pool = entries.fold<num>(0, (sum, entry) => sum + entry.value);
  final goal = target < pool ? target : pool;
  final goalUnits = (goal * 1000).round();
  final raw = [for (final entry in entries) entry.value / pool * goal];
  final cuts = [for (final value in raw) (value * 1000).floor()];
  var extra = goalUnits - cuts.fold<int>(0, (sum, value) => sum + value);
  final order = List<int>.generate(entries.length, (index) => index)
    ..sort((a, b) => ((raw[b] * 1000) - cuts[b]).compareTo((raw[a] * 1000) - cuts[a]));
  for (final index in order) {
    if (extra <= 0) break;
    final cap = (entries[index].value * 1000).floor();
    if (cuts[index] >= cap) continue;
    cuts[index] += 1;
    extra -= 1;
  }
  return [
    for (var i = 0; i < entries.length; i++)
      if (cuts[i] > 0)
        SavingCut(
          category: entries[i].key,
          observed: _round3(entries[i].value),
          reduction: _round3(cuts[i] / 1000),
        ),
  ];
}

AssistantTurn answerFinance(
  String question,
  AssistantLedger ledger, {
  TalkContext context = const TalkContext(),
  required String language,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final lang = _replyLanguage(language, question);
  final understood = understandQuestion(question);
  var intent = understood.intent;
  var period = understood.period;
  var token = understood.categoryToken;
  var amount = understood.amount;
  var months = understood.months;
  var currency = understood.currency ?? ledger.currency;

  if (understood.followUp && context.intent != null) {
    final explicitPeriod = _periodOf(foldQuestion(question));
    period = explicitPeriod ?? context.period;
    token ??= context.categoryToken;
    amount ??= context.amount;
    months ??= context.months;
    if (understood.why) {
      intent = AssistantIntent.spendingComparison;
    } else if (explicitPeriod != null && (context.categories.isNotEmpty || token != null)) {
      intent = AssistantIntent.spendingByCategory;
    } else if (explicitPeriod != null) {
      intent = AssistantIntent.spendingComparison;
    } else {
      intent = context.intent!;
    }
  }
  if (understood.ambiguous && !understood.followUp) {
    intent = AssistantIntent.clarify;
  }

  if (!ledger.loaded || (ledger.hold != null && intent != AssistantIntent.walletBalance)) {
    final text = ledger.hold != null && ledger.loaded ? ledger.hold! : _loading(lang);
    return _turn(answered: false, text: text, intent: intent, context: context, confidence: understood.confidence);
  }

  final window = _window(period, clock);
  final label = _periodLabel(period, window, lang);
  final spending = ledger.hasEvents ? _totals(ledger.events, window, ledger.currency) : <String, num>{};
  final match = _matchCategories(token, spending.isEmpty ? _totals(ledger.events, periodWindow('monthly', clock), ledger.currency) : spending);
  final activeCategories = token == null
      ? context.categories
      : match.clarify
          ? match.names
          : match.names;

  TalkContext nextContext({List<String>? categories, bool clear = false}) {
    return TalkContext(
      intent: intent,
      categoryToken: token ?? context.categoryToken,
      categories: clear ? const [] : (categories ?? (activeCategories.isEmpty ? context.categories : activeCategories)),
      period: period,
      amount: amount ?? context.amount,
      months: months ?? context.months,
      currency: currency,
    );
  }

  if (intent == AssistantIntent.clarify) {
    return _turn(
      answered: true,
      text: lang == 'en'
          ? 'I can read that in more than one way. Do you want a spending total, a category, or a savings plan?'
          : lang == 'ar'
              ? 'يمكن فهم السؤال بأكثر من طريقة. هل تريد مجموع المصروفات أم فئة أم خطة ادخار؟'
              : 'Je peux comprendre cette question de plusieurs façons. Tu veux un total de dépenses, une catégorie, ou un plan d’épargne ?',
      intent: intent,
      context: nextContext(),
      confidence: understood.confidence,
    );
  }

  switch (intent) {
    case AssistantIntent.spendingByCategory:
      if (token == null && context.categories.isEmpty) {
        intent = AssistantIntent.spendingTotal;
        break;
      }
      final names = token == null ? context.categories : match.names;
      if (token != null && match.clarify) {
        final lines = [
          for (final name in match.names) '$name (${_money(spending[name] ?? 0, ledger.currency)})',
        ];
        final text = lang == 'en'
            ? '“$token” matches several categories $label: ${lines.join(', ')}. Which one should I use?'
            : lang == 'ar'
                ? '« $token » يطابق عدة فئات $label: ${lines.join('، ')}. أي واحدة تريد؟'
                : '« $token » correspond à plusieurs catégories $label : ${lines.join(', ')}. Laquelle je prends ?';
        return _turn(
          answered: true,
          text: text,
          intent: AssistantIntent.clarify,
          context: nextContext(categories: match.names),
        );
      }
      if (names.isEmpty) {
        final text = lang == 'en'
            ? 'No recorded category matches “$token” $label. I am not adding one. Total for that request: ${_money(0, ledger.currency)}.'
            : lang == 'ar'
                ? 'لا توجد فئة مسجلة تطابق « $token » $label. لم أضف فئة. المجموع ${_money(0, ledger.currency)}.'
                : 'Aucune catégorie enregistrée ne correspond à « $token » $label. Je n’en ajoute pas. Total : ${_money(0, ledger.currency)}.';
        return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
      }
      num sum = 0;
      for (final name in names) {
        sum += spending[name] ?? 0;
      }
      sum = _round3(sum);
      final shown = names.join(', ');
      final text = lang == 'en'
          ? 'You spent ${_money(sum, ledger.currency)} on $shown $label. Internal transfers and refunds are excluded.'
          : lang == 'ar'
              ? 'أنفقت ${_money(sum, ledger.currency)} على $shown $label. التحويلات الداخلية غير محسوبة.'
              : lang == 'tn'
                  ? '$label sraft ${_money(sum, ledger.currency)} fel $shown. El virements mouch mahsoubin.'
                  : 'Tu as dépensé ${_money(sum, ledger.currency)} pour $shown $label. Les transferts internes et les remboursements sont exclus.';
      return _turn(answered: true, text: text, intent: intent, context: nextContext(categories: names));
    case AssistantIntent.incomeTotal:
      final income = ledger.hasEvents
          ? _totalOf(_totals(ledger.events, window, ledger.currency, income: true))
          : _round3(ledger.aggregateIncome ?? 0);
      final text = lang == 'en'
          ? 'Recorded income $label is ${_money(income, ledger.currency)}. Transfers are not counted as income.'
          : lang == 'ar'
              ? 'الدخل المسجل $label هو ${_money(income, ledger.currency)}. التحويلات ليست دخلاً.'
              : 'Les revenus enregistrés $label sont ${_money(income, ledger.currency)}. Les transferts ne sont pas comptés comme des revenus.';
      return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
    case AssistantIntent.walletBalance:
      if (!ledger.walletsReady) return _turn(answered: false, text: _loading(lang), intent: intent, context: context);
      final same = ledger.wallets.where((wallet) => wallet.currency == ledger.currency).toList();
      if (same.isEmpty) {
        final text = lang == 'fr'
            ? 'Aucun portefeuille en ${ledger.currency} n’est chargé.'
            : lang == 'ar'
                ? 'لا توجد محفظة بعملة ${ledger.currency}.'
                : 'No ${ledger.currency} wallet is loaded.';
        return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
      }
      final net = _round3(same.fold<num>(0, (sum, wallet) => sum + wallet.balance));
      final lines = [for (final wallet in same) '${wallet.name}: ${_money(wallet.balance, wallet.currency)}'];
      final text = lang == 'en'
          ? 'Net balance across your ${ledger.currency} wallets: ${_money(net, ledger.currency)}. ${lines.join(' · ')}.'
          : lang == 'ar'
              ? 'صافي رصيد محافظ ${ledger.currency}: ${_money(net, ledger.currency)}. ${lines.join(' · ')}.'
              : lang == 'tn'
                  ? '3andek ${_money(net, ledger.currency)} fi les wallets. ${lines.join(' · ')}.'
                  : 'Le solde net de tes portefeuilles ${ledger.currency} est ${_money(net, ledger.currency)}. ${lines.join(' · ')}.';
      return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
    case AssistantIntent.budgetStatus:
      final rows = ledger.budgets.where((budget) => budget.currency == ledger.currency).toList();
      if (rows.isEmpty) {
        final text = lang == 'fr'
            ? 'Aucun budget actif n’est enregistré pour ${ledger.currency}.'
            : lang == 'ar'
                ? 'لا توجد ميزانية نشطة بعملة ${ledger.currency}.'
                : 'No active ${ledger.currency} budget is recorded.';
        return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
      }
      final lines = [
        for (final budget in rows)
          '${budget.name}: ${_money(budget.spent, budget.currency)} / ${_money(budget.limit, budget.currency)} (${budget.period})',
      ];
      final text = lang == 'en'
          ? 'Budget status: ${lines.join('; ')}.'
          : lang == 'ar'
              ? 'حالة الميزانية: ${lines.join('؛ ')}.'
              : 'État des budgets : ${lines.join(' ; ')}.';
      return _turn(answered: true, text: text, intent: intent, context: nextContext(clear: true));
    case AssistantIntent.topExpenseCategories:
      final source = spending.isEmpty && !ledger.hasEvents
          ? <String, num>{if (ledger.aggregateTopCategory != null) ledger.aggregateTopCategory!: ledger.aggregateTopAmount ?? 0}
          : spending;
      if (source.isEmpty) {
        return _turn(answered: true, text: _none(lang, label), intent: intent, context: nextContext(clear: true));
      }
      final ranked = source.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topName = ranked.first.key;
      final text = lang == 'en'
          ? 'Your largest category $label is $topName at ${_money(ranked.first.value, ledger.currency)}.'
          : lang == 'ar'
              ? 'أكبر فئة $label هي $topName بمبلغ ${_money(ranked.first.value, ledger.currency)}.'
              : 'La catégorie qui coûte le plus $label est $topName (${_money(ranked.first.value, ledger.currency)}).';
      return _turn(
        answered: true,
        text: text,
        intent: intent,
        context: nextContext(categories: [topName]),
      );
    case AssistantIntent.savingGoalPlan:
    case AssistantIntent.savingAdvice:
      return _savings(lang, ledger, clock, amount, months, currency, intent, nextContext());
    case AssistantIntent.affordability:
      return _afford(lang, ledger, clock, amount, currency, nextContext());
    case AssistantIntent.subscriptionAnalysis:
      return _subscriptions(lang, ledger, clock, nextContext());
    case AssistantIntent.anomalyExplanation:
      return _anomalies(lang, ledger, clock, token, nextContext());
    case AssistantIntent.cashflowForecast:
      return _forecast(lang, ledger, clock, nextContext());
    case AssistantIntent.goalProgress:
      return _goals(lang, ledger, nextContext());
    case AssistantIntent.investmentSummary:
      return _investments(lang, ledger, nextContext());
    case AssistantIntent.spendingComparison:
      return _compare(
        lang,
        ledger,
        clock,
        period,
        context.categories,
        understood.why,
      );
    case AssistantIntent.unknown:
      if (understood.followUp && context.intent != null) break;
      final text = lang == 'en'
          ? 'I can answer from your SmartWallet records: spending, income, wallets, budgets, goals, and a savings simulation. Ask about one of those.'
          : lang == 'ar'
              ? 'أستطيع الإجابة من سجلات SmartWallet: المصروفات والدخل والمحافظ والميزانيات والأهداف ومحاكاة الادخار.'
              : 'Je réponds à partir de tes enregistrements SmartWallet : dépenses, revenus, portefeuilles, budgets, objectifs et simulation d’épargne. Pose une question sur l’un de ces sujets.';
      return _turn(answered: false, text: text, intent: intent, context: context, confidence: understood.confidence);
    case AssistantIntent.clarify:
    case AssistantIntent.spendingTotal:
      break;
  }

  final spent = ledger.aggregateOnly ? ledger.aggregateSpent : _totalOf(spending);
  if (ledger.aggregateOnly && spent == null) {
    return _turn(answered: false, text: _loading(lang), intent: AssistantIntent.spendingTotal, context: context);
  }
  final resolvedSpent = spent ?? 0;
  if (resolvedSpent == 0 && ledger.aggregateOnly) {
    final text = lang == 'ar'
        ? 'لا توجد مصروفات كافية هذا الشهر للإجابة.'
        : lang == 'en'
            ? 'There are no expenses recorded for this month yet.'
            : 'Il n’y a pas encore de dépenses ce mois-ci.';
    return _turn(answered: true, text: text, intent: AssistantIntent.spendingTotal, context: nextContext(clear: true));
  }
  if (resolvedSpent == 0) {
    return _turn(answered: true, text: _none(lang, label), intent: AssistantIntent.spendingTotal, context: nextContext(clear: true));
  }
  final shown = _money(resolvedSpent, ledger.currency);
  if (period != 'month') {
    final text = switch (lang) {
      'tn' => '$label sraft $shown.',
      'ar' => 'المصروف $label هو $shown.',
      'en' => 'You spent $shown $label. Internal transfers and refunds are excluded.',
      _ => 'Tu as dépensé $shown $label. Les transferts internes et les remboursements sont exclus.',
    };
    return _turn(answered: true, text: text, intent: AssistantIntent.spendingTotal, context: nextContext());
  }
  String? topName = ledger.aggregateTopCategory;
  num? topAmount = ledger.aggregateTopAmount;
  if (ledger.hasEvents && spending.isNotEmpty) {
    final ranked = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    topName = ranked.first.key;
    topAmount = ranked.first.value;
  }
  final text = switch (lang) {
    'ar' => topName == null || topAmount == null
        ? 'أنفقت $shown هذا الشهر.'
        : 'أنفقت $shown هذا الشهر. أكبر فئة هي $topName بمبلغ ${_money(topAmount, ledger.currency)}.',
    'en' => topName == null || topAmount == null
        ? 'You spent $shown this month.'
        : 'You spent $shown this month. Your largest category was $topName at ${_money(topAmount, ledger.currency)}.',
    'tn' => '$label sraft $shown.',
    _ => topName == null || topAmount == null
        ? 'Vous avez dépensé $shown ce mois-ci.'
        : 'Vous avez dépensé $shown ce mois-ci. La plus grosse catégorie est $topName (${_money(topAmount, ledger.currency)}).',
  };
  return _turn(
    answered: true,
    text: text,
    intent: AssistantIntent.spendingTotal,
    context: nextContext(categories: topName == null ? const [] : [topName]),
  );
}

AssistantTurn _compare(
  String lang,
  AssistantLedger ledger,
  DateTime clock,
  String period,
  List<String> categories,
  bool why,
) {
  final weekly = period == 'week' || period == 'last_week';
  final currentWindow = _window(weekly ? 'week' : 'month', clock);
  final previousWindowValue = previousWindow(weekly ? 'weekly' : 'monthly', clock);
  final current = _totals(ledger.events, currentWindow, ledger.currency);
  final prior = _totals(ledger.events, previousWindowValue, ledger.currency);
  final currentLabel = _periodLabel(weekly ? 'week' : 'month', currentWindow, lang);
  final priorLabel = _periodLabel(weekly ? 'last_week' : 'last_month', previousWindowValue, lang);
  num currentSum = _totalOf(current);
  num priorSum = _totalOf(prior);
  if (categories.isNotEmpty && ledger.hasEvents) {
    currentSum = 0;
    priorSum = 0;
    for (final name in categories) {
      currentSum += current[name] ?? 0;
      priorSum += prior[name] ?? 0;
    }
    currentSum = _round3(currentSum);
    priorSum = _round3(priorSum);
  } else if (!ledger.hasEvents) {
    currentSum = ledger.aggregateThisWeek ?? ledger.aggregateSpent ?? 0;
    priorSum = ledger.aggregateLastWeek ?? 0;
  }
  final delta = _round3(currentSum - priorSum);
  final more = delta > 0;
  final base = lang == 'en'
      ? '${more ? 'Yes' : delta < 0 ? 'No' : 'They are equal'}. $currentLabel: ${_money(currentSum, ledger.currency)}. $priorLabel: ${_money(priorSum, ledger.currency)}. Difference: ${_money(delta.abs(), ledger.currency)}. Transfers are excluded.'
      : lang == 'ar'
          ? '${more ? 'نعم، المصروف أعلى' : delta < 0 ? 'لا، المصروف أقل' : 'المبلغان متساويان'}. $currentLabel: ${_money(currentSum, ledger.currency)}. $priorLabel: ${_money(priorSum, ledger.currency)}. الفرق ${_money(delta.abs(), ledger.currency)}.'
          : '${more ? 'Oui, tu as dépensé plus' : delta < 0 ? 'Non, tu as dépensé moins' : 'Les deux montants sont égaux'}. $currentLabel : ${_money(currentSum, ledger.currency)}. $priorLabel : ${_money(priorSum, ledger.currency)}. Écart : ${_money(delta.abs(), ledger.currency)}. Hors transferts et remboursements.';
  var text = base;
  if (why) {
    final deltas = <String, num>{};
    final names = categories.isNotEmpty ? categories.toSet() : {...current.keys, ...prior.keys};
    for (final name in names) {
      deltas[name] = _round3((current[name] ?? 0) - (prior[name] ?? 0));
    }
    final ranked = deltas.entries.toList()..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final drivers = ranked.take(3).where((entry) => entry.value != 0).map((entry) {
      final sign = entry.value > 0 ? '+' : '−';
      return '$sign${_money(entry.value.abs(), ledger.currency)} ${entry.key}';
    }).join(', ');
    text = drivers.isEmpty
        ? '$base ${lang == 'fr' ? 'Aucune catégorie ne change entre ces périodes.' : lang == 'ar' ? 'لا يوجد فرق بين الفئات.' : 'No category changed between these periods.'}'
        : '$base ${lang == 'fr' ? 'Les écarts les plus visibles : $drivers.' : lang == 'ar' ? 'أوضح الفروقات: $drivers.' : 'Largest category gaps: $drivers.'}';
  }
  return _turn(
    answered: true,
    text: text,
    intent: AssistantIntent.spendingComparison,
    context: TalkContext(
      intent: AssistantIntent.spendingComparison,
      period: weekly ? 'week' : 'month',
      categories: categories,
    ),
  );
}

AssistantTurn _savings(
  String lang,
  AssistantLedger ledger,
  DateTime clock,
  num? amount,
  int? months,
  String currency,
  AssistantIntent intent,
  TalkContext context,
) {
  final window = periodWindow('monthly', clock);
  final totals = _totals(ledger.events, window, ledger.currency);
  final flexible = <String, num>{};
  num essential = 0;
  totals.forEach((name, value) {
    final group = _groupForName(name);
    if (group != null && _essential.contains(group)) {
      essential = _round3(essential + value);
    } else {
      flexible[name] = value;
    }
  });
  final target = amount ?? _round3(_totalOf(flexible) * 0.1);
  if (currency != ledger.currency) {
    final text = lang == 'fr'
        ? 'Je n’ai pas de taux de change, donc je ne convertis pas $currency en ${ledger.currency}. Aucun montant n’a été inventé.'
        : lang == 'ar'
            ? 'لا يوجد سعر صرف، لذلك لا أحوّل $currency إلى ${ledger.currency}.'
            : 'I have no exchange rate, so I am not converting $currency into ${ledger.currency}.';
    return _turn(answered: true, text: text, intent: intent, context: context);
  }
  final monthlyTarget = months != null && months > 1 ? _round3(target / months) : target;
  final cuts = planCuts(flexible, monthlyTarget);
  final reduced = _round3(cuts.fold<num>(0, (sum, cut) => sum + cut.reduction));
  final horizon = months != null && months > 1
      ? (lang == 'en'
          ? 'over $months months, about ${_money(monthlyTarget, ledger.currency)} per month'
          : lang == 'ar'
              ? 'على $months أشهر، حوالي ${_money(monthlyTarget, ledger.currency)} شهريًا'
              : 'sur $months mois, soit environ ${_money(monthlyTarget, ledger.currency)} par mois')
      : (lang == 'en' ? 'for this month' : lang == 'ar' ? 'لهذا الشهر' : 'pour ce mois-ci');
  if (cuts.isEmpty) {
    final text = lang == 'fr'
        ? 'Je ne vois pas de dépense compressible $horizon. Les dépenses essentielles observées sont ${_money(essential, ledger.currency)}. Ce plan est une simulation et ne garantit pas un résultat.'
        : lang == 'ar'
            ? 'لا أرى مصروفًا يمكن خفضه $horizon. هذه محاكاة ولا تضمن بلوغ الهدف.'
            : 'I cannot see flexible spending $horizon. Essential spending on record is ${_money(essential, ledger.currency)}. This is a simulation and does not guarantee the result.';
    return _turn(answered: true, text: text, intent: intent, context: context.copy(intent: intent, amount: target, months: months), simulation: true);
  }
  final pieces = [
    for (final cut in cuts) '${cut.category} ${_money(cut.reduction, ledger.currency)}',
  ];
  final short = reduced + 0.001 < monthlyTarget
      ? (lang == 'fr'
          ? ' Le maximum observable est ${_money(reduced, ledger.currency)}, inférieur à ${_money(monthlyTarget, ledger.currency)}.'
          : lang == 'ar'
              ? ' الحد الممكن من السجلات هو ${_money(reduced, ledger.currency)}.'
              : ' The most the recorded flexible spending allows is ${_money(reduced, ledger.currency)}.')
      : '';
  final ask = months == null && amount != null
      ? (lang == 'fr'
          ? ' Dis-moi si ces ${_money(target, ledger.currency)} sont pour ce mois-ci ou un total sur plusieurs mois.'
          : lang == 'ar'
              ? ' هل هذا المبلغ لهذا الشهر أم مجموع لعدة أشهر؟'
              : ' Tell me if ${_money(target, ledger.currency)} is for this month or a total over several months.')
      : '';
  final text = lang == 'en'
      ? 'To save ${_money(target, ledger.currency)} $horizon, you could cut ${pieces.join(', ')}. Each cut stays within the spending recorded in that category. Essential spending left untouched: ${_money(essential, ledger.currency)}.$short This is a simulation based on recent spending and does not guarantee the goal.$ask'
      : lang == 'ar'
          ? 'للادخار ${_money(target, ledger.currency)} $horizon، يمكن خفض ${pieces.join('، ')}. كل خفض لا يتجاوز المصروف المسجل في فئته. المصروف الأساسي غير الممسوس: ${_money(essential, ledger.currency)}.$short هذه محاكاة مبنية على مصروفاتك الأخيرة ولا تضمن بلوغ الهدف.$ask'
          : 'Pour économiser ${_money(target, ledger.currency)} $horizon, tu pourrais réduire ${pieces.join(', ')}. Chaque réduction reste dans les dépenses réellement observées de sa catégorie. Dépenses essentielles non touchées : ${_money(essential, ledger.currency)}.$short Ce plan est une simulation basée sur tes dépenses récentes et ne garantit pas que l’objectif sera atteint.$ask';
  return _turn(
    answered: true,
    text: text,
    intent: intent,
    context: context.copy(intent: intent, amount: target, months: months),
    simulation: true,
    cuts: cuts,
  );
}

AssistantTurn _afford(String lang, AssistantLedger ledger, DateTime clock, num? amount, String currency, TalkContext context) {
  if (amount == null) {
    return _turn(
      answered: true,
      text: lang == 'fr' ? 'Indique le prix pour que je le compare à tes soldes.' : 'Tell me the price to compare with your balances.',
      intent: AssistantIntent.affordability,
      context: context,
    );
  }
  if (currency != ledger.currency) {
    final text = lang == 'fr'
        ? 'Le prix est en $currency et les portefeuilles utilisés ici sont en ${ledger.currency}. Sans taux de change, je ne conclus pas.'
        : 'The price is in $currency and the loaded wallets are in ${ledger.currency}. I will not invent an exchange rate.';
    return _turn(answered: true, text: text, intent: AssistantIntent.affordability, context: context);
  }
  if (!ledger.walletsReady) {
    return _turn(answered: false, text: _loading(lang), intent: AssistantIntent.affordability, context: context);
  }
  final net = _round3(ledger.wallets.where((wallet) => wallet.currency == currency).fold<num>(0, (sum, wallet) => sum + wallet.balance));
  final month = periodWindow('monthly', clock);
  final income = _totalOf(_totals(ledger.events, month, currency, income: true));
  final expense = _totalOf(_totals(ledger.events, month, currency));
  final surplus = _round3(income - expense);
  final covered = net + 0.001 >= amount;
  final text = lang == 'en'
      ? 'A ${ _money(amount, currency)} purchase is ${covered ? 'covered' : 'not covered'} by the current net wallet balance of ${_money(net, currency)}. This month’s recorded surplus is ${_money(surplus, currency)}. Nothing was purchased. This is a check, not a guarantee.'
      : lang == 'ar'
          ? 'شراء ${_money(amount, currency)} ${covered ? 'يغطيه' : 'لا يغطيه'} صافي الرصيد الحالي ${_money(net, currency)}. فائض هذا الشهر المسجل ${_money(surplus, currency)}. لم يُسجَّل أي شراء.'
          : 'Un achat de ${_money(amount, currency)} ${covered ? 'est couvert' : 'n’est pas couvert'} par le solde net actuel de ${_money(net, currency)}. Le surplus enregistré ce mois-ci est ${_money(surplus, currency)}. Aucun achat n’a été enregistré. C’est une vérification, pas une garantie.';
  return _turn(answered: true, text: text, intent: AssistantIntent.affordability, context: context.copy(intent: AssistantIntent.affordability, amount: amount), simulation: true);
}

AssistantTurn _subscriptions(String lang, AssistantLedger ledger, DateTime clock, TalkContext context) {
  final rows = [
    for (final event in ledger.events)
      if (countsAsSpending(event) && (event.merchant ?? '').trim().isNotEmpty)
        TxnObs(
          id: '${event.date.millisecondsSinceEpoch}-${event.amount}-${event.merchant}',
          date: event.date,
          type: event.type,
          amount: event.amount,
          currency: event.currency,
          merchant: event.merchant,
          category: event.categoryName,
        ),
  ];
  final hits = detectSubscriptions(rows, now: clock).where((hit) => hit.currency == ledger.currency).toList();
  if (hits.isEmpty) {
    final text = lang == 'fr'
        ? 'Aucun abonnement régulier n’est détecté dans les commerçants enregistrés. Je n’en invente pas.'
        : lang == 'ar'
            ? 'لم يُكتشف اشتراك منتظم في التجار المسجلين.'
            : 'No regular subscription is detected from the recorded merchants. I am not inventing one.';
    return _turn(answered: true, text: text, intent: AssistantIntent.subscriptionAnalysis, context: context);
  }
  final lines = [
    for (final hit in hits) '${hit.name}: ${_money(hit.typicalAmount, hit.currency)} / ${hit.cadence}',
  ];
  final text = lang == 'fr'
      ? 'Abonnements détectés à partir des répétitions réelles : ${lines.join(' ; ')}. Ceci est une détection statistique, pas un prélèvement.'
      : lang == 'ar'
          ? 'اشتراكات مكتشفة من التكرار الفعلي: ${lines.join('؛ ')}.'
          : 'Subscriptions detected from real repeats: ${lines.join('; ')}. This is a statistical detection, not a charge.';
  return _turn(answered: true, text: text, intent: AssistantIntent.subscriptionAnalysis, context: context, simulation: true);
}

AssistantTurn _anomalies(String lang, AssistantLedger ledger, DateTime clock, String? token, TalkContext context) {
  final current = _totals(ledger.events, periodWindow('monthly', clock), ledger.currency);
  final prior = _totals(ledger.events, previousWindow('monthly', clock), ledger.currency);
  final lines = <String>[];
  final names = token == null ? {...current.keys, ...prior.keys} : _matchCategories(token, current).names.toSet();
  for (final name in names) {
    final nowSpent = current[name] ?? 0;
    final then = prior[name] ?? 0;
    if (then > 0 && nowSpent > then * 1.5 && nowSpent - then >= 20) {
      lines.add('$name ${_money(then, ledger.currency)} → ${_money(nowSpent, ledger.currency)}');
    }
  }
  if (lines.isEmpty) {
    final text = lang == 'fr'
        ? 'Aucune catégorie ne dépasse de moitié les dépenses du mois précédent sur les enregistrements chargés.'
        : lang == 'ar'
            ? 'لا توجد فئة تتجاوز مصروف الشهر السابق بالنصف في السجلات المحملة.'
            : 'No category is more than 50% above last month in the loaded records.';
    return _turn(answered: true, text: text, intent: AssistantIntent.anomalyExplanation, context: context);
  }
  final text = lang == 'fr'
      ? 'Écarts observables, sans modèle entraîné : ${lines.join(' ; ')}.'
      : lang == 'ar'
          ? 'فروقات ملحوظة بدون نموذج مدرَّب: ${lines.join('؛ ')}.'
          : 'Observable gaps, not a trained model: ${lines.join('; ')}.';
  return _turn(answered: true, text: text, intent: AssistantIntent.anomalyExplanation, context: context);
}

AssistantTurn _forecast(String lang, AssistantLedger ledger, DateTime clock, TalkContext context) {
  final days = <DateTime>{};
  num spent = 0;
  final start = clock.subtract(const Duration(days: 90));
  for (final event in ledger.events) {
    if (!countsAsSpending(event) || event.currency != ledger.currency) continue;
    final date = event.date.toLocal();
    if (date.isBefore(start) || !date.isBefore(clock.add(const Duration(days: 1)))) continue;
    days.add(DateTime(date.year, date.month, date.day));
    spent += event.amount;
  }
  if (days.length < 14) {
    final text = lang == 'fr'
        ? 'Historique insuffisant pour une prévision à 7, 30 ou 90 jours (${days.length} jour(s) avec une dépense). Étiquette : insufficient_history. Aucun montant futur n’est présenté comme une prévision fiable.'
        : lang == 'ar'
            ? 'السجل غير كافٍ لتوقع 7 أو 30 أو 90 يومًا (${days.length} يومًا). insufficient_history.'
            : 'History is too short for a 7, 30, or 90 day forecast (${days.length} spending day(s)). Label: insufficient_history.';
    return _turn(answered: true, text: text, intent: AssistantIntent.cashflowForecast, context: context, simulation: true);
  }
  final daily = _round3(spent / days.length);
  final text = lang == 'fr'
      ? 'Simulation statistique, pas un modèle SARIMAX validé. Dépense quotidienne moyenne ${_money(daily, ledger.currency)} sur ${days.length} jours. 7 jours : ${_money(_round3(daily * 7), ledger.currency)}. 30 jours : ${_money(_round3(daily * 30), ledger.currency)}. 90 jours : ${_money(_round3(daily * 90), ledger.currency)}.'
      : lang == 'ar'
          ? 'محاكاة إحصائية. المتوسط اليومي ${_money(daily, ledger.currency)}. 7 أيام ${_money(_round3(daily * 7), ledger.currency)}، 30 يومًا ${_money(_round3(daily * 30), ledger.currency)}، 90 يومًا ${_money(_round3(daily * 90), ledger.currency)}.'
          : 'Statistical simulation, not a validated SARIMAX model. Average daily spend ${_money(daily, ledger.currency)} over ${days.length} days. 7 days: ${_money(_round3(daily * 7), ledger.currency)}. 30 days: ${_money(_round3(daily * 30), ledger.currency)}. 90 days: ${_money(_round3(daily * 90), ledger.currency)}.';
  return _turn(answered: true, text: text, intent: AssistantIntent.cashflowForecast, context: context, simulation: true);
}

AssistantTurn _goals(String lang, AssistantLedger ledger, TalkContext context) {
  if (ledger.goals.isEmpty) {
    final text = lang == 'fr'
        ? 'Aucun objectif actif à commenter.'
        : lang == 'ar'
            ? 'لا يوجد هدف نشط للحديث عنه.'
            : 'There is no active goal to comment on.';
    return _turn(answered: false, text: text, intent: AssistantIntent.goalProgress, context: context);
  }
  final lines = [
    for (final goal in ledger.goals)
      '${goal.name}: ${_money(goal.saved, goal.currency)} / ${_money(goal.target, goal.currency)}, reste ${_money(goal.gap, goal.currency)}',
  ];
  final text = lang == 'fr'
      ? 'Progression des objectifs : ${lines.join(' ; ')}.'
      : lang == 'ar'
          ? 'تقدم الأهداف: ${lines.join('؛ ')}.'
          : 'Goal progress: ${lines.join('; ')}.';
  return _turn(answered: true, text: text, intent: AssistantIntent.goalProgress, context: context);
}

AssistantTurn _investments(String lang, AssistantLedger ledger, TalkContext context) {
  if (ledger.assets.isEmpty) {
    final text = lang == 'fr'
        ? 'Aucun investissement enregistré. Aucun ordre n’est passé.'
        : lang == 'ar'
            ? 'لا يوجد استثمار مسجل. لم يُرسل أي أمر.'
            : 'No investment is recorded. No order was sent.';
    return _turn(answered: true, text: text, intent: AssistantIntent.investmentSummary, context: context);
  }
  final lines = [
    for (final asset in ledger.assets)
      '${asset.label}: ${asset.gain == null ? (lang == 'fr' ? 'gain non calculé' : 'gain unavailable') : _money(asset.gain!, asset.currency)}${asset.manualPrice ? (lang == 'fr' ? ' (prix manuel)' : lang == 'ar' ? ' (سعر يدوي)' : ' (manual price)') : ''}',
  ];
  final text = lang == 'fr'
      ? 'Synthèse des investissements, sans transaction automatique : ${lines.join(' ; ')}.'
      : lang == 'ar'
          ? 'ملخص الاستثمارات بدون تنفيذ تلقائي: ${lines.join('؛ ')}.'
          : 'Investment summary, with no automatic trade: ${lines.join('; ')}.';
  return _turn(answered: true, text: text, intent: AssistantIntent.investmentSummary, context: context, simulation: true);
}
