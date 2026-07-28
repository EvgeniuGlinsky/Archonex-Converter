import 'package:equatable/equatable.dart';

/// The calendar month a usage count belongs to.
///
/// A calendar month rather than a rolling thirty day window: a window anchored
/// on the day of first use has no honest answer for the 31st in February, and
/// "the count refills on the 1st" is one line to explain on screen.
final class QuotaPeriod extends Equatable {
  const QuotaPeriod({required this.year, required this.month});

  QuotaPeriod.of(DateTime date) : year = date.year, month = date.month;

  /// Rebuilds a period from the single integer [key] it is stored as.
  const QuotaPeriod.fromKey(int key)
      : year = (key - 1) ~/ _monthsInYear,
        month = (key - 1) % _monthsInYear + 1;

  static const int _monthsInYear = 12;

  final int year;

  /// 1 through 12, as in `DateTime.month`.
  final int month;

  /// The stored form: one integer that orders and compares like a date, so no
  /// parsing is needed to tell whether the month has turned over.
  int get key => year * _monthsInYear + month;

  /// Midnight on the first day of the next month — when the count refills.
  DateTime get resetsAt => month == _monthsInYear
      ? DateTime(year + 1)
      : DateTime(year, month + 1);

  @override
  List<Object?> get props => <Object?>[year, month];
}
