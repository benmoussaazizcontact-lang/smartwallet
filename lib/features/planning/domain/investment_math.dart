class Trade {
  const Trade({
    required this.side,
    required this.quantity,
    required this.unitPrice,
    required this.date,
  });

  final String side;
  final num quantity;
  final num unitPrice;
  final DateTime date;
}

class Position {
  const Position({
    required this.quantity,
    required this.costBasis,
    required this.realized,
    this.rejected = false,
  });

  final num quantity;
  final num costBasis;
  final num realized;
  final bool rejected;
}

Position applyTrades(List<Trade> trades) {
  final ordered = [...trades]..sort((a, b) => a.date.compareTo(b.date));
  num quantity = 0;
  num cost = 0;
  num realized = 0;
  for (final trade in ordered) {
    if (trade.quantity <= 0 || trade.unitPrice < 0) {
      return Position(quantity: quantity, costBasis: cost, realized: realized, rejected: true);
    }
    if (trade.side == 'buy') {
      cost += trade.quantity * trade.unitPrice;
      quantity += trade.quantity;
      continue;
    }
    if (trade.side != 'sell' || trade.quantity > quantity + 0.0000001) {
      return Position(quantity: quantity, costBasis: cost, realized: realized, rejected: true);
    }
    final average = quantity == 0 ? 0 : cost / quantity;
    final soldCost = average * trade.quantity;
    realized += trade.quantity * trade.unitPrice - soldCost;
    cost -= soldCost;
    quantity -= trade.quantity;
  }
  return Position(quantity: quantity, costBasis: cost, realized: realized);
}

num? unrealizedGain(Position position, num? currentPrice) {
  if (position.rejected || currentPrice == null) return null;
  return position.quantity * currentPrice - position.costBasis;
}

class AllocationSlice {
  const AllocationSlice({required this.label, required this.value, required this.share});

  final String label;
  final num value;
  final double share;
}

class Allocation {
  const Allocation({
    required this.currency,
    required this.slices,
    required this.concentrated,
    required this.missingPrices,
  });

  final String currency;
  final List<AllocationSlice> slices;
  final bool concentrated;
  final int missingPrices;
}

Allocation allocate({
  required String currency,
  required List<({String label, num? value})> holdings,
}) {
  final priced = holdings.where((row) => row.value != null && row.value! > 0).toList();
  final missing = holdings.length - priced.length;
  num total = 0;
  for (final row in priced) {
    total += row.value!;
  }
  if (total <= 0) {
    return Allocation(
      currency: currency,
      slices: const [],
      concentrated: false,
      missingPrices: missing,
    );
  }
  final slices = [
    for (final row in priced)
      AllocationSlice(
        label: row.label,
        value: row.value!,
        share: (row.value! / total).toDouble(),
      ),
  ];
  return Allocation(
    currency: currency,
    slices: slices,
    concentrated: slices.any((slice) => slice.share > 0.40),
    missingPrices: missing,
  );
}
