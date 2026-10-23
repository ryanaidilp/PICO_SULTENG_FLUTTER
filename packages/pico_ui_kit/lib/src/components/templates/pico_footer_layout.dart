import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A layout widget that positions a child above a footer.
///
/// Uses [CustomMultiChildLayout] to first lay out the footer at the
/// bottom, then gives the remaining space to the body.
///
/// ```dart
/// PicoFooterLayout(
///   footer: PicoButton(
///     label: 'Continue',
///     isExpanded: true,
///     onPressed: () {},
///   ),
///   child: ListView(
///     children: [...],
///   ),
/// )
/// ```
class const PicoFooterLayout({
  super.key,

  /// The widget to position at the bottom of the available space.
  final Widget? footer,

  /// The primary content of the [PicoFooterLayout].
  final Widget? child,
}) extends StatelessWidget {
  /// Creates a layout with its child widget above a footer widget.
  this;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
    delegate: _FooterLayoutDelegate(),
    children: <Widget>[
      if (child != null) LayoutId(id: _Slot.body, child: child!),
      if (footer != null) LayoutId(id: _Slot.footer, child: footer!),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Widget?>('footer', footer))
      ..add(DiagnosticsProperty<Widget?>('child', child));
  }
}

enum _Slot() {
  body,
  footer,
}

class _FooterLayoutDelegate() extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    var footerSize = Size.zero;

    if (hasChild(_Slot.footer)) {
      footerSize = layoutChild(_Slot.footer, BoxConstraints.loose(size));
      final footerOffset = Offset(0, size.height - footerSize.height);
      positionChild(_Slot.footer, footerOffset);
    }

    if (hasChild(_Slot.body)) {
      final bodySize = Size(size.width, size.height - footerSize.height);
      layoutChild(_Slot.body, BoxConstraints.loose(bodySize));
      positionChild(_Slot.body, Offset.zero);
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) =>
      oldDelegate != this;
}
