import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Widget de pull-to-refresh personnalisé avec icône d'actualisation rotative.
class MuseRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const MuseRefreshControl({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      refreshTriggerPullDistance: 80.0,
      refreshIndicatorExtent: 60.0,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        return _MuseRefreshIndicator(
          refreshState: refreshState,
          pulledExtent: pulledExtent,
          refreshTriggerPullDistance: refreshTriggerPullDistance,
        );
      },
    );
  }
}

class _MuseRefreshIndicator extends StatefulWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double refreshTriggerPullDistance;

  const _MuseRefreshIndicator({
    required this.refreshState,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
  });

  @override
  State<_MuseRefreshIndicator> createState() => _MuseRefreshIndicatorState();
}

class _MuseRefreshIndicatorState extends State<_MuseRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(_MuseRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshState == RefreshIndicatorMode.refresh) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
        _rotationController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Zone bleue/thématique
    final bandColor = theme.primaryColor.withValues(alpha: 0.1);
    final accentColor = theme.primaryColor;

    return Container(
      color: bandColor,
      height: widget.pulledExtent,
      alignment: Alignment.center,
      child: widget.pulledExtent > 20
          ? RotationTransition(
              turns: _rotationController,
              child: Image.asset(
                'assets/images/actualisation.png',
                width: (widget.pulledExtent * 0.5).clamp(24.0, 42.0),
                height: (widget.pulledExtent * 0.5).clamp(24.0, 42.0),
                color: accentColor,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
