import 'package:flutter/material.dart';

import '../../../core/domain/task_priority.dart';
import '../../../core/theme/app_colors.dart';

Color priorityColour(TaskPriority priority, AppColors c) => switch (priority) {
      TaskPriority.high => c.priorityHigh,
      TaskPriority.medium => c.priorityMedium,
      TaskPriority.low => c.priorityLow,
    };

String priorityName(TaskPriority priority) => switch (priority) {
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
    };
