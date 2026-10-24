import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_font_family.dart';
import 'package:pico_ui_kit/src/foundations/typography/pico_typography_token.dart';

/// Typography foundation providing pre-configured text styles.
@immutable
class const PicoTypographyFoundation({
  final PicoFontFamily _fontFamily = const PicoFontFamily(),

  /// Font size overrides by scale key: display1-3, h1-h6, bodyLarge, body,
  /// bodySmall, caption, overline. Missing keys keep the token size; button
  /// and code styles follow body, bodySmall and caption.
  final Map<String, double> _sizes = const <String, double>{},
}) {
  TextStyle get display1 => _fontFamily.headingTextStyle(
    fontSize: _sizes['display1'] ?? PicoTypographyToken.sizeDisplay1,
    fontWeight: PicoTypographyToken.weightBold,
    height: PicoTypographyToken.heightDisplay,
    letterSpacing: PicoTypographyToken.trackingTight,
  );
  TextStyle get display2 => _fontFamily.headingTextStyle(
    fontSize: _sizes['display2'] ?? PicoTypographyToken.sizeDisplay2,
    fontWeight: PicoTypographyToken.weightBold,
    height: PicoTypographyToken.heightDisplay,
    letterSpacing: PicoTypographyToken.trackingTight,
  );
  TextStyle get display3 => _fontFamily.headingTextStyle(
    fontSize: _sizes['display3'] ?? PicoTypographyToken.sizeDisplay3,
    fontWeight: PicoTypographyToken.weightBold,
    height: PicoTypographyToken.heightDisplay,
    letterSpacing: PicoTypographyToken.trackingTight,
  );

  TextStyle get h1 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h1'] ?? PicoTypographyToken.sizeH1,
    fontWeight: PicoTypographyToken.weightBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingTight,
  );
  TextStyle get h2 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h2'] ?? PicoTypographyToken.sizeH2,
    fontWeight: PicoTypographyToken.weightBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingTight,
  );
  TextStyle get h3 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h3'] ?? PicoTypographyToken.sizeH3,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get h4 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h4'] ?? PicoTypographyToken.sizeH4,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get h5 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h5'] ?? PicoTypographyToken.sizeH5,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get h6 => _fontFamily.headingTextStyle(
    fontSize: _sizes['h6'] ?? PicoTypographyToken.sizeH6,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightHeading,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );

  TextStyle get bodyLarge => _fontFamily.bodyTextStyle(
    fontSize: _sizes['bodyLarge'] ?? PicoTypographyToken.sizeBodyLarge,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get body => _fontFamily.bodyTextStyle(
    fontSize: _sizes['body'] ?? PicoTypographyToken.sizeBody,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get bodySmall => _fontFamily.bodyTextStyle(
    fontSize: _sizes['bodySmall'] ?? PicoTypographyToken.sizeBodySmall,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get bodyLargeMedium => _fontFamily.bodyTextStyle(
    fontSize: _sizes['bodyLarge'] ?? PicoTypographyToken.sizeBodyLarge,
    fontWeight: PicoTypographyToken.weightMedium,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get bodyMedium => _fontFamily.bodyTextStyle(
    fontSize: _sizes['body'] ?? PicoTypographyToken.sizeBody,
    fontWeight: PicoTypographyToken.weightMedium,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get bodySmallMedium => _fontFamily.bodyTextStyle(
    fontSize: _sizes['bodySmall'] ?? PicoTypographyToken.sizeBodySmall,
    fontWeight: PicoTypographyToken.weightMedium,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );

  TextStyle get caption => _fontFamily.bodyTextStyle(
    fontSize: _sizes['caption'] ?? PicoTypographyToken.sizeCaption,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get captionMedium => _fontFamily.bodyTextStyle(
    fontSize: _sizes['caption'] ?? PicoTypographyToken.sizeCaption,
    fontWeight: PicoTypographyToken.weightMedium,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get overline => _fontFamily.bodyTextStyle(
    fontSize: _sizes['overline'] ?? PicoTypographyToken.sizeOverline,
    fontWeight: PicoTypographyToken.weightMedium,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingWider,
  );

  TextStyle get buttonLarge => _fontFamily.bodyTextStyle(
    fontSize: _sizes['body'] ?? PicoTypographyToken.sizeBody,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingWide,
  );
  TextStyle get button => _fontFamily.bodyTextStyle(
    fontSize: _sizes['bodySmall'] ?? PicoTypographyToken.sizeBodySmall,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingWide,
  );
  TextStyle get buttonSmall => _fontFamily.bodyTextStyle(
    fontSize: _sizes['caption'] ?? PicoTypographyToken.sizeCaption,
    fontWeight: PicoTypographyToken.weightSemiBold,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingWide,
  );

  TextStyle get code => _fontFamily.monoTextStyle(
    fontSize: _sizes['bodySmall'] ?? PicoTypographyToken.sizeBodySmall,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightBody,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
  TextStyle get codeSmall => _fontFamily.monoTextStyle(
    fontSize: _sizes['caption'] ?? PicoTypographyToken.sizeCaption,
    fontWeight: PicoTypographyToken.weightRegular,
    height: PicoTypographyToken.heightCaption,
    letterSpacing: PicoTypographyToken.trackingNormal,
  );
}
