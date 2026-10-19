import 'package:flutter/material.dart';

import 'tokens.dart';

enum DsButtonVariant { primary, secondary, ghost, destructive }

enum DsButtonSize { regular, compact }

/// Controlled button. For async work use [DsAsyncButton], or own [loading].
class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final DsButtonSize size;
  final bool loading, fullWidth;
  final IconData? icon;
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DsButtonVariant.primary,
    this.size = DsButtonSize.regular,
    this.loading = false,
    this.fullWidth = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = loading ? null : onPressed;
    final compact = size == DsButtonSize.compact;
    final ghost = variant == DsButtonVariant.ghost;
    final foreground = switch (variant) {
      DsButtonVariant.primary || DsButtonVariant.destructive => Colors.white,
      DsButtonVariant.secondary || DsButtonVariant.ghost => DsColors.ink,
    };
    final content = Stack(
      alignment: Alignment.center,
      children: [
        // Retain the original intrinsic size while the progress indicator is shown.
        Opacity(
          opacity: loading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
      ],
    );
    final style = ButtonStyle(
      backgroundColor:
          loading &&
              (variant == DsButtonVariant.primary ||
                  variant == DsButtonVariant.destructive)
          ? WidgetStatePropertyAll(
              variant == DsButtonVariant.destructive
                  ? DsColors.critical
                  : DsColors.moss,
            )
          : null,
      minimumSize: WidgetStatePropertyAll(Size(0, compact ? 48 : 54)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: ghost ? 8 : (compact ? 16 : 22),
          vertical: compact ? 10 : 15,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ghost ? DsRadius.control : DsRadius.button,
          ),
        ),
      ),
    );
    final button = switch (variant) {
      DsButtonVariant.primary => FilledButton(
        style: style,
        onPressed: enabled,
        child: content,
      ),
      DsButtonVariant.secondary => OutlinedButton(
        style: style,
        onPressed: enabled,
        child: content,
      ),
      DsButtonVariant.ghost => TextButton(
        style: style,
        onPressed: enabled,
        child: content,
      ),
      DsButtonVariant.destructive => FilledButton(
        style: style.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? DsColors.critical.withValues(alpha: .45)
                : DsColors.critical,
          ),
        ),
        onPressed: enabled,
        child: content,
      ),
    };
    return Semantics(
      label: label,
      value: loading ? '처리 중' : null,
      onTap: enabled,
      liveRegion: loading,
      excludeSemantics: true,
      button: true,
      enabled: enabled != null,
      child: fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

/// Prevents duplicate submissions. Errors go to [onError]; without a handler they
/// are reported to Flutter's error pipeline, never swallowed or rendered as text.
class DsAsyncButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressed;
  final void Function(Object error, StackTrace stack)? onError;
  final DsButtonVariant variant;
  final bool fullWidth;
  const DsAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onError,
    this.variant = DsButtonVariant.primary,
    this.fullWidth = false,
  });
  @override
  State<DsAsyncButton> createState() => _DsAsyncButtonState();
}

class _DsAsyncButtonState extends State<DsAsyncButton> {
  bool busy = false;
  Future<void> submit() async {
    if (busy || widget.onPressed == null) return;
    setState(() => busy = true);
    try {
      await widget.onPressed!();
    } catch (error, stack) {
      if (widget.onError != null) {
        widget.onError!(error, stack);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'daengle_design',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DsButton(
    label: widget.label,
    onPressed: widget.onPressed == null ? null : submit,
    loading: busy,
    fullWidth: widget.fullWidth,
    variant: widget.variant,
  );
}

class DsIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const DsIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: onPressed,
    icon: Icon(icon, size: 24),
  );
}
