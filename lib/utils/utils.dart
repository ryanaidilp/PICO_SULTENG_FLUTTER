import 'package:intl/intl.dart';

String formatNumber(dynamic number) {
  return NumberFormat.decimalPattern('id').format(number);
}

final preventions = [
  {'assets/images/wash_hands.png': 'Mencuci Tangan'},
  {'assets/images/social_distancing.png': 'Menjaga Jarak'},
  {'assets/images/wear_mask.png': 'Memakai Masker'},
];
