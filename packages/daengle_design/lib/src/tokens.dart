import 'package:flutter/material.dart';

/// Daengle semantic palette. Brand color is reserved for actions and selection.
abstract final class DsColors {
  static const ink = Color(0xFF242925);
  static const muted = Color(0xFF687169);
  static const moss = Color(0xFF52664E);
  static const sage = Color(0xFF7F927B);
  static const canvas = Color(0xFFFFFFFF);
  static const field = Color(0xFFF5F6F3);
  static const selected = Color(0xFFEEF2EB);
  static const line = Color(0xFFE9ECE6);
  static const critical = Color(0xFFB3443B);
}

abstract final class DsSpace {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      lg = 16.0,
      xl = 24.0,
      xxl = 32.0,
      section = 40.0;
}

abstract final class DsRadius {
  static const control = 12.0, button = 16.0, panel = 20.0;
}
