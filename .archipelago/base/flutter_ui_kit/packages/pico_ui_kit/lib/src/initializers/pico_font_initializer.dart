import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Initializer for preloading Google Fonts.
abstract final class PicoFontInitializer() {
  static Future<void> initialize() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w400),
    ]);
  }
}
