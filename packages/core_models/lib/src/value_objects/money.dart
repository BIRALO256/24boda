import 'package:core_models/src/contracts/contract_parsing.dart';

/// An integer monetary amount in a specific ISO 4217 currency.
final class Money {
  const Money({required this.amount, this.currency = 'UGX'})
    : assert(amount >= 0),
      assert(currency.length == 3);

  final int amount;
  final String currency;

  factory Money.ugx(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    return Money(amount: amount);
  }

  factory Money.fromMap(Map<String, dynamic> map) => Money(
    amount: ContractParsing.integer(map['amount'], 'amount', minimum: 0),
    currency: ContractParsing.string(map['currency'], 'currency').toUpperCase(),
  );

  Map<String, dynamic> toMap() => {'amount': amount, 'currency': currency};

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    final result = amount - other.amount;
    if (result < 0) throw StateError('Money cannot become negative');
    return Money(amount: result, currency: currency);
  }

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot combine $currency and ${other.currency}');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
