/// One expense. Immutable, with value equality.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amountPaise,
    required this.spentAt,
  });

  final String id;
  final String title;

  /// Money as whole paise, never a `double`.
  final int amountPaise;

  /// Always UTC; convert to local time only for display.
  final DateTime spentAt;

  Expense copyWith({String? title, int? amountPaise, DateTime? spentAt}) =>
      Expense(
        id: id,
        title: title ?? this.title,
        amountPaise: amountPaise ?? this.amountPaise,
        spentAt: spentAt ?? this.spentAt,
      );

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.title == title &&
      other.amountPaise == amountPaise &&
      other.spentAt == spentAt;

  @override
  int get hashCode => Object.hash(id, title, amountPaise, spentAt);

  @override
  String toString() => 'Expense($id, $title, $amountPaise)';
}

/// Parses what a user types as rupees ("240", "240.5", "240.50") into paise.
/// Returns null for anything else.
int? parseRupees(String input) {
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(input.trim());
  if (match == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return int.parse(match.group(1)!) * 100 + int.parse(fraction);
}
