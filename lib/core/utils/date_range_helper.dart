class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }
}

class DateRangeHelper {
  // Harian: 00:00:00 sampai 23:59:59.999
  static DateRange getDailyRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return DateRange(start: start, end: end);
  }

  // Mingguan: Senin 00:00:00 sampai Minggu 23:59:59.999
  static DateRange getWeeklyRange(DateTime date) {
    // weekday: 1 (Mon) -> 7 (Sun)
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0, 0);
    final sunday = monday.add(const Duration(days: 6));
    final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
    return DateRange(start: start, end: end);
  }

  // Bulanan: tanggal 1 00:00:00 sampai hari terakhir bulan 23:59:59.999
  static DateRange getMonthlyRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1, 0, 0, 0, 0);
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    final end = DateTime(date.year, date.month, lastDay, 23, 59, 59, 999);
    return DateRange(start: start, end: end);
  }
}
