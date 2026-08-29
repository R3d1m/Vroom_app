import 'package:flutter/material.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/user_model.dart';

class VerificationBadge extends StatelessWidget {
  final NidStatus nidStatus;
  final StudentIdStatus studentIdStatus;
  final bool showLabel;

  const VerificationBadge({
    super.key,
    required this.nidStatus,
    this.studentIdStatus = StudentIdStatus.verified,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (nidStatus == NidStatus.verified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: VroomColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: VroomColors.accent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 13, color: VroomColors.text),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'NID Verified',
                    style: TextStyle(
                      color: VroomColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (studentIdStatus == StudentIdStatus.verified) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: VroomColors.secondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: VroomColors.primary, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 13, color: VroomColors.text),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'Student',
                    style: TextStyle(
                      color: VroomColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
