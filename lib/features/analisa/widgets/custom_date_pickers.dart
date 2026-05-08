import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showCustomMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _MonthPickerDialog(initialDate: initialDate);
    },
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthPickerDialog({required this.initialDate});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF2E3B84);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH BULAN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${_months[_selectedMonth - 1]} $_selectedYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() {
                            _selectedYear--;
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _selectedYear.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() {
                            _selectedYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final isSelected = (index + 1) == _selectedMonth;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonth = index + 1;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF858AB5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _months[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0), // Light purple/gray
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, DateTime(_selectedYear, _selectedMonth, 1));
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: headerColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------

Future<DateTime?> showCustomYearPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _YearPickerDialog(initialDate: initialDate);
    },
  );
}

class _YearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _YearPickerDialog({required this.initialDate});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;
  late int _startYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    // Calculate the start year of the 12-year grid
    _startYear = _selectedYear - (_selectedYear % 12);
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF2E3B84);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH TAHUN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '$_selectedYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Year Range Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() {
                            _startYear -= 12;
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$_startYear - ${_startYear + 11}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() {
                            _startYear += 12;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Years Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final year = _startYear + index;
                      final isSelected = year == _selectedYear;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedYear = year;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF858AB5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, DateTime(_selectedYear, 1, 1));
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: headerColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------

Future<DateTime?> showCustomDayPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _DayPickerDialog(initialDate: initialDate);
    },
  );
}

class _DayPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _DayPickerDialog({required this.initialDate});
  @override
  State<_DayPickerDialog> createState() => _DayPickerDialogState();
}

class _DayPickerDialogState extends State<_DayPickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;

  final List<String> _weekdays = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
  int _firstWeekdayOffset(DateTime date) {
    final d = DateTime(date.year, date.month, 1);
    return d.weekday == 7 ? 0 : d.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF2E3B84);
    final dateStr = DateFormat('E, d MMM yyyy', 'id_ID').format(_selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH TANGGAL',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1); });
                        },
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(_months[_displayMonth.month - 1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text('${_displayMonth.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1); });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays.map((w) => SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(w, style: const TextStyle(color: Color(0xFF2E3B84), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: _daysInMonth(_displayMonth) + _firstWeekdayOffset(_displayMonth),
                    itemBuilder: (context, index) {
                      if (index < _firstWeekdayOffset(_displayMonth)) {
                        return const SizedBox.shrink();
                      }
                      final day = index - _firstWeekdayOffset(_displayMonth) + 1;
                      final currentDate = DateTime(_displayMonth.year, _displayMonth.month, day);
                      final isSelected = currentDate.year == _selectedDate.year &&
                                         currentDate.month == _selectedDate.month &&
                                         currentDate.day == _selectedDate.day;
                      return GestureDetector(
                        onTap: () {
                          setState(() { _selectedDate = currentDate; });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF858AB5) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _selectedDate),
                        style: TextButton.styleFrom(
                          backgroundColor: headerColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  required DateTimeRange initialDateRange,
}) async {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (BuildContext context) {
      return _DateRangePickerDialog(initialDateRange: initialDateRange);
    },
  );
}

class _DateRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;
  const _DateRangePickerDialog({required this.initialDateRange});
  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayMonth;

  final List<String> _weekdays = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange.start;
    _endDate = widget.initialDateRange.end;
    _displayMonth = DateTime(_startDate!.year, _startDate!.month, 1);
  }

  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
  int _firstWeekdayOffset(DateTime date) {
    final d = DateTime(date.year, date.month, 1);
    return d.weekday == 7 ? 0 : d.weekday;
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF2E3B84);
    final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Start';
    final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'End';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH RENTANG',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(startStr, style: TextStyle(color: headerColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      const Text('—', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(endStr, style: TextStyle(color: headerColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1); });
                        },
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(_months[_displayMonth.month - 1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text('${_displayMonth.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                        onPressed: () {
                          setState(() { _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1); });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays.map((w) => SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(w, style: const TextStyle(color: Color(0xFF2E3B84), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: _daysInMonth(_displayMonth) + _firstWeekdayOffset(_displayMonth),
                    itemBuilder: (context, index) {
                      if (index < _firstWeekdayOffset(_displayMonth)) {
                        return const SizedBox.shrink();
                      }
                      final day = index - _firstWeekdayOffset(_displayMonth) + 1;
                      final currentDate = DateTime(_displayMonth.year, _displayMonth.month, day);
                      
                      bool isStart = _startDate != null && _isSameDay(currentDate, _startDate!);
                      bool isEnd = _endDate != null && _isSameDay(currentDate, _endDate!);
                      bool inRange = _startDate != null && _endDate != null &&
                                     currentDate.isAfter(_startDate!) && currentDate.isBefore(_endDate!);
                      bool hasBothDates = _startDate != null && _endDate != null && !_isSameDay(_startDate!, _endDate!);

                      Color outerColor = Colors.transparent;
                      if (hasBothDates && (inRange || isStart || isEnd)) {
                        outerColor = const Color(0xFF858AB5).withOpacity(0.3);
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_startDate == null || (_startDate != null && _endDate != null)) {
                              _startDate = currentDate;
                              _endDate = null;
                            } else if (_startDate != null && _endDate == null) {
                              if (currentDate.isBefore(_startDate!)) {
                                _endDate = _startDate;
                                _startDate = currentDate;
                              } else {
                                _endDate = currentDate;
                              }
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: outerColor,
                            borderRadius: isStart && hasBothDates ? const BorderRadius.horizontal(left: Radius.circular(100)) : 
                                          isEnd && hasBothDates ? const BorderRadius.horizontal(right: Radius.circular(100)) : 
                                          BorderRadius.zero,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isStart || isEnd ? const Color(0xFF858AB5) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isStart || isEnd ? Colors.white : Colors.black87,
                                fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569))),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_startDate != null && _endDate != null) {
                            Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate!));
                          } else if (_startDate != null && _endDate == null) {
                             Navigator.pop(context, DateTimeRange(start: _startDate!, end: _startDate!));
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: headerColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
