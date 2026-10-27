// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expenses';

  @override
  String get emptyExpenses => 'No expenses yet. Add your first one.';

  @override
  String get addExpense => 'Add expense';

  @override
  String get titleLabel => 'What for?';

  @override
  String get amountLabel => 'Amount (₹)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get errorLoading => 'Couldn\'t load your expenses.';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidAmount => 'Enter an amount like 240 or 240.50';

  @override
  String total(String amount) {
    return 'Total: $amount';
  }
}
