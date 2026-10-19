import 'package:flutter/material.dart';

import 'tokens.dart';

enum DsTone { neutral, selected, critical }

class DsBadge extends StatelessWidget {
  final String label;
  final DsTone tone;
  const DsBadge({super.key, required this.label, this.tone = DsTone.neutral});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: tone == DsTone.selected ? DsColors.selected : DsColors.field,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: switch (tone) {
          DsTone.neutral => DsColors.ink,
          DsTone.selected => DsColors.moss,
          DsTone.critical => DsColors.critical,
        },
      ),
    ),
  );
}

class DsNotice extends StatelessWidget {
  final String message;
  final DsTone tone;
  const DsNotice({
    super.key,
    required this.message,
    this.tone = DsTone.neutral,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: tone == DsTone.critical,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == DsTone.critical
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            size: 20,
            color: tone == DsTone.critical ? DsColors.critical : DsColors.moss,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                height: 1.5,
                color: tone == DsTone.critical
                    ? DsColors.critical
                    : DsColors.ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class DsEmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Widget? action;
  const DsEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.pets_outlined,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(icon, color: DsColors.moss, size: 40),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DsColors.muted, height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

Future<bool> showDsConfirm(
  BuildContext context, {
  required String title,
  required String description,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: DsColors.critical)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
