import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';

/// Modern Stay Dates Section widget for the new booking flow
/// Features compact side-by-side layout with popup circular roller pickers
class StayDatesSection extends ConsumerWidget {
  const StayDatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(newBookingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side-by-side check-in / check-out cards
          Row(
            children: [
              Expanded(
                child: _CompactDateTimeCard(
                  label: 'Check In',
                  dateTime: bookingState.checkIn,
                  icon: Icons.login_rounded,
                  onTap: () => _showDateTimePicker(
                    context,
                    ref,
                    isCheckIn: true,
                    currentDateTime: bookingState.checkIn,
                    minDate: DateTime.now(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactDateTimeCard(
                  label: 'Check Out',
                  dateTime: bookingState.checkOut,
                  icon: Icons.logout_rounded,
                  onTap: () => _showDateTimePicker(
                    context,
                    ref,
                    isCheckIn: false,
                    currentDateTime: bookingState.checkOut,
                    minDate: bookingState.checkIn.add(const Duration(days: 1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nights badge centered
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nights_stay, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${bookingState.numberOfNights} ${bookingState.numberOfNights == 1 ? 'Night' : 'Nights'}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateTimePicker(
    BuildContext context,
    WidgetRef ref, {
    required bool isCheckIn,
    required DateTime currentDateTime,
    required DateTime minDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateTimePickerSheet(
        isCheckIn: isCheckIn,
        initialDateTime: currentDateTime,
        minDate: minDate,
        onDateTimeChanged: (dateTime) {
          final notifier = ref.read(newBookingProvider.notifier);
          if (isCheckIn) {
            notifier.setCheckInDate(dateTime);
            notifier.setCheckInTime(TimeOfDay.fromDateTime(dateTime));
          } else {
            notifier.setCheckOutDate(dateTime);
            notifier.setCheckOutTime(TimeOfDay.fromDateTime(dateTime));
          }
        },
      ),
    );
  }
}

/// Compact date/time card for side-by-side layout
class _CompactDateTimeCard extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final IconData icon;
  final VoidCallback onTap;

  const _CompactDateTimeCard({
    required this.label,
    required this.dateTime,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, size: 14, color: AppColors.grey400),
                ],
              ),
            ),
            // Date display
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('d MMM yyyy').format(dateTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Time display
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('h:mm a').format(dateTime),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey700,
                      ),
                    ),
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

/// Bottom sheet with circular roller pickers for date and time
class _DateTimePickerSheet extends StatefulWidget {
  final bool isCheckIn;
  final DateTime initialDateTime;
  final DateTime minDate;
  final ValueChanged<DateTime> onDateTimeChanged;

  const _DateTimePickerSheet({
    required this.isCheckIn,
    required this.initialDateTime,
    required this.minDate,
    required this.onDateTimeChanged,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDateTime;
  int _currentTab = 0; // 0 = date, 1 = time

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  void _updateDateTime(DateTime newDateTime) {
    setState(() => _selectedDateTime = newDateTime);
    widget.onDateTimeChanged(newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isCheckIn
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isCheckIn ? 'Check In' : 'Check Out',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'EEE, d MMM • h:mm a',
                      ).format(_selectedDateTime),
                      style: TextStyle(fontSize: 14, color: AppColors.grey600),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Date',
                    icon: Icons.calendar_today_rounded,
                    isSelected: _currentTab == 0,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Time',
                    icon: Icons.access_time_rounded,
                    isSelected: _currentTab == 1,
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Picker content
          SizedBox(
            height: 220,
            child: _currentTab == 0
                ? _CircularDatePicker(
                    selectedDate: _selectedDateTime,
                    minDate: widget.minDate,
                    onDateChanged: (date) {
                      _updateDateTime(
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          _selectedDateTime.hour,
                          _selectedDateTime.minute,
                        ),
                      );
                    },
                  )
                : _CircularTimePicker(
                    selectedTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    onTimeChanged: (time) {
                      _updateDateTime(
                        DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 20),

          // Reset and Done buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                // Reset button (only for check-in)
                if (widget.isCheckIn)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          // Round to nearest 15 minutes
                          final minutes = now.minute;
                          int roundedMinutes;
                          int hourAdjustment = 0;
                          if (minutes < 8) {
                            roundedMinutes = 0;
                          } else if (minutes < 23) {
                            roundedMinutes = 15;
                          } else if (minutes < 38) {
                            roundedMinutes = 30;
                          } else if (minutes < 53) {
                            roundedMinutes = 45;
                          } else {
                            roundedMinutes = 0;
                            hourAdjustment = 1;
                          }
                          final roundedNow = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            now.hour + hourAdjustment,
                            roundedMinutes,
                          );
                          _updateDateTime(roundedNow);
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reset to Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.black,
                          side: const BorderSide(color: AppColors.grey300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.isCheckIn) const SizedBox(width: 12),
                // Done button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Tab button for date/time selector
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.black : AppColors.grey500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.black : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular looping date picker using ListWheelScrollView with looping
class _CircularDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime minDate;
  final ValueChanged<DateTime> onDateChanged;

  const _CircularDatePicker({
    required this.selectedDate,
    required this.minDate,
    required this.onDateChanged,
  });

  @override
  State<_CircularDatePicker> createState() => _CircularDatePickerState();
}

class _CircularDatePickerState extends State<_CircularDatePicker> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int get _daysInMonth => DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  int get _minYear => widget.minDate.year;
  int get _maxYear => DateTime.now().year + 5;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate.day;
    _selectedMonth = widget.selectedDate.month - 1;
    _selectedYear = widget.selectedDate.year;

    // For looping, start at a large offset so user can scroll both directions
    _dayController = FixedExtentScrollController(
      initialItem: 1000 * 31 + (_selectedDay - 1),
    );
    _monthController = FixedExtentScrollController(
      initialItem: 1000 * 12 + _selectedMonth,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CircularDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jump to new position when date changes externally (e.g., reset button)
    if (oldWidget.selectedDate != widget.selectedDate) {
      final newDay = widget.selectedDate.day;
      final newMonth = widget.selectedDate.month - 1;
      final newYear = widget.selectedDate.year;

      // Defer jumpToItem until after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Calculate position based on current offset to maintain looping
        final dayOffset =
            _dayController.selectedItem - ((_dayController.selectedItem) % 31);
        _dayController.jumpToItem(dayOffset + (newDay - 1));

        final monthOffset =
            _monthController.selectedItem -
            ((_monthController.selectedItem) % 12);
        _monthController.jumpToItem(monthOffset + newMonth);

        final yearTarget = newYear - _minYear;
        if (yearTarget >= 0 && yearTarget <= _maxYear - _minYear) {
          _yearController.jumpToItem(yearTarget);
        }
      });

      // Update local state immediately
      _selectedDay = newDay;
      _selectedMonth = newMonth;
      _selectedYear = newYear;
    }
  }

  void _updateDate() {
    final maxDay = _daysInMonth;
    if (_selectedDay > maxDay) {
      _selectedDay = maxDay;
    }

    var newDate = DateTime(_selectedYear, _selectedMonth + 1, _selectedDay);

    if (newDate.isBefore(widget.minDate)) {
      newDate = widget.minDate;
      _selectedYear = newDate.year;
      _selectedMonth = newDate.month - 1;
      _selectedDay = newDate.day;
    }

    widget.onDateChanged(newDate);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Day picker (circular)
          Expanded(
            flex: 2,
            child: _buildCircularPicker(
              controller: _dayController,
              itemCount: 31,
              isLooping: true,
              itemBuilder: (index) => '${(index % 31) + 1}',
              onChanged: (index) {
                setState(() => _selectedDay = (index % 31) + 1);
                _updateDate();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Month picker (circular)
          Expanded(
            flex: 3,
            child: _buildCircularPicker(
              controller: _monthController,
              itemCount: 12,
              isLooping: true,
              itemBuilder: (index) => _months[index % 12],
              onChanged: (index) {
                setState(() => _selectedMonth = index % 12);
                _updateDate();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Year picker (not circular - finite range)
          Expanded(
            flex: 3,
            child: _buildCircularPicker(
              controller: _yearController,
              itemCount: _maxYear - _minYear + 1,
              isLooping: false,
              itemBuilder: (index) => '${_minYear + index}',
              onChanged: (index) {
                setState(() => _selectedYear = _minYear + index);
                _updateDate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required bool isLooping,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 48,
            perspective: 0.002,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.3,
            magnification: 1.15,
            useMagnifier: true,
            onSelectedItemChanged: onChanged,
            childDelegate: isLooping
                ? ListWheelChildLoopingListDelegate(
                    children: List.generate(
                      itemCount,
                      (index) => Center(
                        child: Text(
                          itemBuilder(index),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, index) => Center(
                      child: Text(
                        itemBuilder(index),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Circular looping time picker (15-minute intervals)
class _CircularTimePicker extends StatefulWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _CircularTimePicker({
    required this.selectedTime,
    required this.onTimeChanged,
  });

  @override
  State<_CircularTimePicker> createState() => _CircularTimePickerState();
}

class _CircularTimePickerState extends State<_CircularTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;

  late int _selectedHour;
  late int _selectedMinuteIndex;
  late int _selectedPeriod;

  final List<int> _minutes = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedTime.hour >= 12 ? 1 : 0;
    _selectedHour = widget.selectedTime.hour % 12;
    if (_selectedHour == 0) _selectedHour = 12;
    _selectedMinuteIndex = (widget.selectedTime.minute / 15).round() % 4;

    // For looping, start at a large offset
    _hourController = FixedExtentScrollController(
      initialItem: 1000 * 12 + (_selectedHour - 1),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: 1000 * 4 + _selectedMinuteIndex,
    );
    _periodController = FixedExtentScrollController(
      initialItem: _selectedPeriod, // Non-looping, use direct index
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CircularTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jump to new position when time changes externally (e.g., reset button)
    if (oldWidget.selectedTime != widget.selectedTime) {
      final newPeriod = widget.selectedTime.hour >= 12 ? 1 : 0;
      var newHour = widget.selectedTime.hour % 12;
      if (newHour == 0) newHour = 12;
      final newMinuteIndex = (widget.selectedTime.minute / 15).round() % 4;

      // Defer jumpToItem until after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final hourOffset =
            _hourController.selectedItem -
            ((_hourController.selectedItem) % 12);
        _hourController.jumpToItem(hourOffset + (newHour - 1));

        final minuteOffset =
            _minuteController.selectedItem -
            ((_minuteController.selectedItem) % 4);
        _minuteController.jumpToItem(minuteOffset + newMinuteIndex);

        _periodController.jumpToItem(newPeriod);
      });

      // Update local state immediately
      _selectedHour = newHour;
      _selectedMinuteIndex = newMinuteIndex;
      _selectedPeriod = newPeriod;
    }
  }

  void _updateTime() {
    int hour24 = _selectedHour;
    if (_selectedPeriod == 0) {
      if (hour24 == 12) hour24 = 0;
    } else {
      if (hour24 != 12) hour24 += 12;
    }

    widget.onTimeChanged(
      TimeOfDay(hour: hour24, minute: _minutes[_selectedMinuteIndex]),
    );
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Hour picker (1-12, circular)
          Expanded(
            flex: 2,
            child: _buildCircularPicker(
              controller: _hourController,
              itemCount: 12,
              itemBuilder: (index) => '${(index % 12) + 1}',
              onChanged: (index) {
                setState(() => _selectedHour = (index % 12) + 1);
                _updateTime();
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),

          // Minute picker (00, 15, 30, 45, circular)
          Expanded(
            flex: 2,
            child: _buildCircularPicker(
              controller: _minuteController,
              itemCount: 4,
              itemBuilder: (index) =>
                  _minutes[index % 4].toString().padLeft(2, '0'),
              onChanged: (index) {
                setState(() => _selectedMinuteIndex = index % 4);
                _updateTime();
              },
            ),
          ),

          const SizedBox(width: 16),

          // AM/PM picker (non-looping - only 2 values)
          Expanded(
            flex: 2,
            child: _buildNonLoopingPicker(
              controller: _periodController,
              itemCount: 2,
              itemBuilder: (index) => index == 0 ? 'AM' : 'PM',
              onChanged: (index) {
                setState(() => _selectedPeriod = index);
                _updateTime();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.002,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        overAndUnderCenterOpacity: 0.3,
        magnification: 1.15,
        useMagnifier: true,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List.generate(
            itemCount,
            (index) => Center(
              child: Text(
                itemBuilder(index),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Non-looping picker for small value sets like AM/PM
  Widget _buildNonLoopingPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.002,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        overAndUnderCenterOpacity: 0.3,
        magnification: 1.15,
        useMagnifier: true,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) => Center(
            child: Text(
              itemBuilder(index),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
