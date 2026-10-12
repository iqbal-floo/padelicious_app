import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api/api_config.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';

/// Opens the session's printable order of play as a PDF in the browser or
/// the device's PDF viewer — the sheet a host pins up at the venue.
class OrderOfPlayButton extends StatelessWidget {
  const OrderOfPlayButton({super.key, required this.sessionId, this.startTime});

  final String sessionId;

  /// First-round start time ("08:15") to print a time column; optional.
  final String? startTime;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return OutlinedButton.icon(
      icon: const Text('📄'),
      label: const Text('Export order of play'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.border),
      ),
      onPressed: () async {
        final uri = Uri.parse(
          ApiConfig.orderOfPlayUrl(sessionId, pdf: true, startTime: startTime),
        );
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) appState.showToast('Could not open the order of play');
      },
    );
  }
}
