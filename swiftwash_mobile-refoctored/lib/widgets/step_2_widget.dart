import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/widgets/custom_icons.dart';

class Step2Widget extends StatefulWidget {
  final PageController pageController;
  final String selectedService;
  final Function(String, String, String, String, double) onUpdate;

  const Step2Widget(
      {super.key,
      required this.pageController,
      required this.selectedService,
      required this.onUpdate});

  @override
  _Step2WidgetState createState() => _Step2WidgetState();
}

class _Step2WidgetState extends State<Step2Widget>
    with TickerProviderStateMixin {
  String? _selectedPickupDate;
  int? _selectedPickupTimeIndex;
  String? _selectedDeliveryDate;
  int? _selectedDeliveryTimeIndex;

  late AnimationController _animationController;

  final List<String> _laundryTimes = [
    '10-12 PM',
    '12-2 PM',
    '2-4 PM',
    '4-6 PM',
    '6-8 PM',
  ];

  final List<String> _swiftTimes = [
    '6-8 AM',
    '8-10 AM',
    '10-12 PM',
    '12-2 PM',
    '2-4 PM',
    '4-6 PM',
    '6-8 PM',
    '8-10 PM',
    '10-12 AM',
  ];

  List<String> get _allTimes =>
      widget.selectedService == 'Swift' ? _swiftTimes : _laundryTimes;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isSelectionComplete {
    final pickupTimes = _getAvailableTimes(_selectedPickupDate);
    final deliveryTimes = _getAvailableTimes(
      _selectedDeliveryDate,
      pickupTime: _selectedPickupTimeIndex != null && pickupTimes.isNotEmpty
          ? pickupTimes[_selectedPickupTimeIndex!]
          : null,
      isDelivery: true,
      pickupDate: _selectedPickupDate,
    );

    final isComplete = _selectedPickupDate != null &&
        _selectedPickupTimeIndex != null &&
        _selectedDeliveryDate != null &&
        _selectedDeliveryTimeIndex != null;

    if (isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onUpdate(
          _selectedPickupDate!,
          pickupTimes[_selectedPickupTimeIndex!],
          _selectedDeliveryDate!,
          deliveryTimes[_selectedDeliveryTimeIndex!],
          0.0,
        );
      });
    }

    return isComplete;
  }

  DateTime _getBaseDate(String? pickupDate) {
    final now = DateTime.now();
    if (pickupDate == 'Tomorrow' || pickupDate == 'Tmrw') {
      return now.add(const Duration(days: 1));
    } else if (pickupDate != 'Today' && pickupDate != null) {
      // This logic needs to be more robust to handle named days of the week
      for (int i = 1; i < 7; i++) {
        final futureDate = now.add(Duration(days: i));
        if (DateFormat('EEE').format(futureDate) == pickupDate) {
          return futureDate;
        }
      }
    }
    return now;
  }

  DateTime _getSlotStartDateTime(String date, String time) {
    final now = DateTime.now();
    DateTime baseDate;

    if (date == 'Today') {
      baseDate = DateTime(now.year, now.month, now.day);
    } else if (date == 'Tomorrow' || date == 'Tmrw') {
      baseDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    } else {
      baseDate = DateTime(now.year, now.month, now.day);
      for (int i = 1; i <= 7; i++) {
        final futureDate = DateTime(now.year, now.month, now.day).add(Duration(days: i));
        if (DateFormat('EEE').format(futureDate) == date) {
          baseDate = futureDate;
          break;
        }
      }
    }

    final timePart = time.split('-')[0];
    final ampmPart = time.split(' ')[1];
    final fullTimeStr = '$timePart $ampmPart';
    final format = DateFormat("h a");
    final parsedTime = format.parse(fullTimeStr);

    return baseDate.add(Duration(hours: parsedTime.hour, minutes: parsedTime.minute));
  }

  DateTime _getSlotEndDateTime(String date, String time) {
    final now = DateTime.now();
    DateTime baseDate;

    if (date == 'Today') {
      baseDate = DateTime(now.year, now.month, now.day);
    } else if (date == 'Tomorrow' || date == 'Tmrw') {
      baseDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    } else {
      baseDate = DateTime(now.year, now.month, now.day);
      for (int i = 1; i <= 7; i++) {
        final futureDate = DateTime(now.year, now.month, now.day).add(Duration(days: i));
        if (DateFormat('EEE').format(futureDate) == date) {
          baseDate = futureDate;
          break;
        }
      }
    }

    final timePart = time.split('-')[1];
    final ampmPart = time.split(' ')[1];
    final fullTimeStr = '$timePart $ampmPart';
    final format = DateFormat("h a");
    final parsedTime = format.parse(fullTimeStr);

    return baseDate.add(Duration(hours: parsedTime.hour, minutes: parsedTime.minute));
  }

  List<String> _getAvailableTimes(String? selectedDate,
      {String? pickupTime, bool isDelivery = false, String? pickupDate}) {
    if (selectedDate == null) {
      return [];
    }

    DateTime now = DateTime.now();
    List<String> availableTimes = List.from(_allTimes);

    if (selectedDate == 'Today') {
      if (widget.selectedService == 'Swift') {
        availableTimes = _allTimes.where((time) {
          final slotEndTime = _getSlotEndDateTime(selectedDate, time);
          final cutoffTime = slotEndTime.subtract(const Duration(minutes: 30));
          return now.isBefore(cutoffTime);
        }).toList();
      } else {
        availableTimes = _allTimes.where((time) {
          final slotStartTime = _getSlotStartDateTime(selectedDate, time);
          return now.isBefore(slotStartTime);
        }).toList();
      }
    }

    if (widget.selectedService == 'Swift') {
      return _getSwiftTimes(selectedDate, availableTimes,
          isDelivery: isDelivery,
          pickupTime: pickupTime,
          pickupDate: pickupDate);
    } else {
      return _getLaundryTimes(selectedDate, availableTimes,
          isDelivery: isDelivery,
          pickupTime: pickupTime,
          pickupDate: pickupDate);
    }
  }

  List<String> _getSwiftTimes(
      String selectedDate, List<String> availableTimes,
      {bool isDelivery = false, String? pickupTime, String? pickupDate}) {
    if (isDelivery) {
      DateTime pickupBaseDate = _getBaseDate(pickupDate);
      String pickupDay = DateFormat('EEE').format(pickupBaseDate);

      // Swift delivery is only on the same day
      if (selectedDate == pickupDay) {
        if (pickupTime != null) {
          int pickupIndex = _allTimes.indexOf(pickupTime);
          if (pickupIndex != -1) {
            // Delivery is within the next 2-4 hours. Show the next 2 available slots.
            int startIndex = pickupIndex + 1;
            if (startIndex < _allTimes.length) {
              int endIndex = startIndex + 2;
              if (endIndex > _allTimes.length) {
                endIndex = _allTimes.length;
              }
              return _allTimes.sublist(startIndex, endIndex);
            }
          }
        }
      }
      return []; // No delivery slots on other days or if something is wrong
    } else {
      // For swift pickup, all available future slots are swift
      return availableTimes;
    }
  }

  List<String> _getLaundryTimes(
      String selectedDate, List<String> availableTimes,
      {bool isDelivery = false, String? pickupTime, String? pickupDate}) {
    if (isDelivery) {
      DateTime pickupBaseDate = _getBaseDate(pickupDate);
      String pickupDay = DateFormat('EEE').format(pickupBaseDate);

      if (selectedDate == pickupDay) {
        if (pickupTime != null) {
          int pickupIndex = _allTimes.indexOf(pickupTime);
          if (pickupIndex != -1) {
            int startIndex = pickupIndex + 3; // Skip next 2 slots
            if (startIndex < _allTimes.length) {
              return _allTimes.sublist(startIndex);
            }
          }
        }
        return []; // No same-day delivery if not enough slots
      } else {
        // For next day delivery, all slots are available
        return _allTimes;
      }
    } else {
      // For pickup, skip the next available slot (1 slot gap)
      if (selectedDate == 'Today') {
        if (availableTimes.length > 1) {
          return availableTimes.sublist(1);
        }
        return [];
      }
      return availableTimes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupTimes = _getAvailableTimes(_selectedPickupDate);
    final deliveryTimes =
        _selectedPickupDate != null && _selectedPickupTimeIndex != null && pickupTimes.isNotEmpty
            ? _getAvailableTimes(
                _selectedDeliveryDate,
                pickupTime: pickupTimes[_selectedPickupTimeIndex!],
                isDelivery: true,
                pickupDate: _selectedPickupDate,
              )
            : <String>[];

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Pickup & Delivery', style: AppTypography.h1),
                const SizedBox(height: 4),
                Text('Select convenient times for pickup and drop-off.',
                    style: AppTypography.subtitle),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildSection(
                      icon: Icon(Icons.shopping_basket),
                      title: 'Pickup',
                      selectedDate: _selectedPickupDate,
                      selectedTimeIndex: _selectedPickupTimeIndex,
                      onDateSelected: (date) => setState(() {
                        _selectedPickupDate = date;
                        _selectedPickupTimeIndex = null;
                        _selectedDeliveryDate = null;
                        _selectedDeliveryTimeIndex = null;
                      }),
                      onTimeSelected: (index) => setState(() {
                        _selectedPickupTimeIndex = index;
                        _selectedDeliveryDate = null;
                        _selectedDeliveryTimeIndex = null;
                      }),
                      times: pickupTimes,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedPickupDate != null &&
                        _selectedPickupTimeIndex != null)
                      _buildSection(
                        icon: Icon(Icons.moped),
                        title: 'Delivery',
                        selectedDate: _selectedDeliveryDate,
                        selectedTimeIndex: _selectedDeliveryTimeIndex,
                        onDateSelected: (date) =>
                            setState(() => _selectedDeliveryDate = date),
                        onTimeSelected: (index) =>
                            setState(() => _selectedDeliveryTimeIndex = index),
                        isDelivery: true,
                        times: deliveryTimes,
                        pickupDate: _selectedPickupDate,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    _isSelectionComplete ? AppColors.bookingCardGradient : null,
                color: _isSelectionComplete ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSelectionComplete
                    ? () {
                        widget.pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup: ${_selectedPickupDate ?? ''} ${(_selectedPickupTimeIndex != null && pickupTimes.isNotEmpty) ? pickupTimes[_selectedPickupTimeIndex!] : ''}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              'Delivery: ${_selectedDeliveryDate ?? ''} ${(_selectedDeliveryTimeIndex != null && deliveryTimes.isNotEmpty) ? deliveryTimes[_selectedDeliveryTimeIndex!] : ''}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Row(
                          children: [
                            Text(
                              'Confirm & Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required Widget icon,
    required String title,
    required String? selectedDate,
    required int? selectedTimeIndex,
    required ValueChanged<String> onDateSelected,
    required ValueChanged<int> onTimeSelected,
    required List<String> times,
    bool isDelivery = false,
    String? pickupDate,
  }) {
    final now = DateTime.now();
    List<String> dates;
    List<String> dateStrings;

    if (isDelivery) {
      DateTime baseDate = _getBaseDate(pickupDate);
      if (widget.selectedService == 'Swift') {
        dates = [DateFormat('EEE').format(baseDate)];
        dateStrings = [DateFormat('MMM d').format(baseDate)];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedDate == null || selectedDate != dates[0]) {
            onDateSelected(dates[0]);
          }
        });
      } else {
        final pickupTimes = _getAvailableTimes(pickupDate);
        if (_selectedPickupTimeIndex != null &&
            pickupTimes.isNotEmpty &&
            _selectedPickupTimeIndex == pickupTimes.length - 1) {
          baseDate = baseDate.add(const Duration(days: 1));
        }
        dates = [];
        dateStrings = [];
        for (int i = 0; i < 3; i++) {
          final dateToCheck = baseDate.add(Duration(days: i));
          final dateLabel = DateFormat('EEE').format(dateToCheck);
          final deliveryTimesForDate = _getAvailableTimes(
            dateLabel,
            pickupTime: (_selectedPickupTimeIndex != null && pickupTimes.isNotEmpty)
                ? pickupTimes[_selectedPickupTimeIndex!]
                : null,
            isDelivery: true,
            pickupDate: pickupDate,
          );
          if (deliveryTimesForDate.isNotEmpty) {
            dates.add(dateLabel);
            dateStrings.add(DateFormat('MMM d').format(dateToCheck));
          }
        }
      }
    } else {
      dates = [];
      dateStrings = [];
      if (now.hour < 20) {
        dates.add('Today');
        dateStrings.add(DateFormat('MMM d').format(now));
      }
      dates.add('Tmrw');
      dateStrings.add(
          DateFormat('MMM d').format(now.add(const Duration(days: 1))));
      dates.add(DateFormat('EEE').format(now.add(const Duration(days: 2))));
      dateStrings.add(
          DateFormat('MMM d').format(now.add(const Duration(days: 2))));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Text(title, style: AppTypography.cardTitle),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select Date', style: AppTypography.cardSubtitle),
          const SizedBox(height: 8),
          Row(
            children: List.generate(dates.length, (index) {
              final date = dates[index];
              final isSelected = selectedDate == date;
              return Expanded(
                child: _DateButton(
                  day: date,
                  date: dateStrings[index],
                  isSelected: isSelected,
                  onPressed: () => onDateSelected(date),
                  isDelivery: isDelivery,
                ),
              );
            }),
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Select Time', style: AppTypography.cardSubtitle),
                if (widget.selectedService == 'Swift') ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Pickup is available within the first 90 minutes of the time slot.',
                    child: Icon(Icons.info_outline,
                        color: Colors.grey.shade600, size: 16),
                  )
                ]
              ],
            ),
            const SizedBox(height: 8),
            if (times.isNotEmpty)
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 2.0,
                ),
                itemCount: times.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final time = times[index];
                  final isSelected = selectedTimeIndex == index;
                  bool isSwift = false;
                  if (widget.selectedService == 'Swift') {
                    isSwift = true;
                  }

                  return _TimeButton(
                    time: time,
                    isSelected: isSelected,
                    onPressed: () => onTimeSelected(index),
                    isSwift: isSwift,
                    animation: _animationController,
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Please select an available time slot from another day.',
                  style: AppTypography.cardSubtitle
                      .copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.selectedService != 'Swift')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'For faster delivery, choose the Swift service from the home screen.',
                  style: AppTypography.cardSubtitle
                      .copyWith(color: AppColors.brandBlue),
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.selectedService == 'Swift' && isDelivery)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Your order will be delivered within 2-4 hours of reaching our facility.',
                  style: AppTypography.cardSubtitle
                      .copyWith(color: AppColors.brandBlue),
                  textAlign: TextAlign.center,
                ),
              )
            else if (widget.selectedService == 'Swift')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'For more affordable options, choose the Laundry service from the home screen.',
                  style: AppTypography.cardSubtitle
                      .copyWith(color: AppColors.brandBlue),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isDelivery;

  const _DateButton({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.onPressed,
    this.isDelivery = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isDelivery
                  ? AppColors.deliveryDateGradient
                  : AppColors.bookingButtonGradient)
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(day,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
            Text(date,
                style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isSwift;
  final Animation<double> animation;

  const _TimeButton({
    required this.time,
    required this.isSelected,
    required this.onPressed,
    this.isSwift = false,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isSwift
                  ? AppColors.swiftOrange.withOpacity(0.2)
                  : AppColors.selectedTimeFill)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
              color: isSelected
                  ? (isSwift
                      ? AppColors.swiftOrange
                      : AppColors.selectedTimeBorder)
                  : Colors.grey.shade300),
          boxShadow: isSwift
              ? [
                  BoxShadow(
                    color: AppColors.swiftOrange
                        .withOpacity(animation.value * 0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time,
                    style: TextStyle(
                        color: isSelected
                            ? (isSwift
                                ? AppColors.swiftOrange
                                : AppColors.selectedTimeBorder)
                            : Colors.black)),
                if (isSwift) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.flash_on, color: AppColors.swiftOrange, size: 16),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
