import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/order_status.dart';

class TimelineWidget extends StatelessWidget {
  final List<OrderStatus> statuses;
  final int currentStatusIndex;

  const TimelineWidget({
    super.key,
    required this.statuses,
    required this.currentStatusIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        return TimelineTile(
          isFirst: index == 0,
          isLast: index == statuses.length - 1,
          isCompleted: index < currentStatusIndex,
          isCurrent: index == currentStatusIndex,
          status: status,
        );
      },
    );
  }
}

class TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final bool isCurrent;
  final OrderStatus status;

  const TimelineTile({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isCompleted,
    required this.isCurrent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? AppColors.brandGreen : Colors.grey,
                ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.brandGreen
                      : isCurrent
                          ? AppColors.brandBlue
                          : Colors.grey,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      )
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? AppColors.brandGreen : Colors.grey,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: AppTypography.cardTitle,
                ),
                Text(
                  status.subtitle,
                  style: AppTypography.cardSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
