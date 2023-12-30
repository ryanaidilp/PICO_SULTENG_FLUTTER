// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';

extension TranslationExtension on BuildContext {
  Translations get i10n => Translations.of(this);
}
