import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/images/network_image/pico_network_image.dart';

part 'pico_circular_bar_item.dart';
part '_pico_circular_bar_label.dart';
part '_pico_circular_progress_bar.dart';

const double _base = 5;
final double _logoSize = 28.r;
const double _denom = 5;
final double _minItemSize = 32.r;
final double _maxBarHeight = 120.h;
const double _specialLineTop = 1.4;
const double _specialLineBottom = 1.3;
final double _itemWidth = 55.w;
final double _itemHeight = 184.h;

/// Per-max value = 1
const double _positiveBottomAnchorPercent = 0.66;
const double _zeroAnchorPercent = 0.5;
const double _negativeBottomAnchorPercent = 0.33;

/// Set label to top when final / max final exceed this (Max = 1)
const double _anchorBound = 0.8;
