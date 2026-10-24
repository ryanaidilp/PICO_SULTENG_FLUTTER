import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the typography showcase component for Widgetbook.
WidgetbookComponent typographyShowcaseComponent() => WidgetbookComponent(
  name: 'Typography',
  useCases: [
    WidgetbookUseCase(
      name: 'Typography Styles',
      builder: (context) => const TypographyStylesShowcase(),
    ),
  ],
);

/// Showcases all typography styles organized by category.
class const TypographyStylesShowcase({super.key}) extends StatelessWidget {
  /// Creates a [TypographyStylesShowcase].
  this;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final spacing = context.spacing;
    final colors = context.colors;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        _SectionTitle(title: 'Display Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Display Large',
          accessor: 'display.large',
          style: typography.display.large,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Display Medium',
          accessor: 'display.medium',
          style: typography.display.medium,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Display Small',
          accessor: 'display.small',
          style: typography.display.small,
          foregroundColor: colors.foreground.main,
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Heading Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Heading 1',
          accessor: 'heading.h1',
          style: typography.heading.h1,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Heading 2',
          accessor: 'heading.h2',
          style: typography.heading.h2,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Heading 3',
          accessor: 'heading.h3',
          style: typography.heading.h3,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Heading 4',
          accessor: 'heading.h4',
          style: typography.heading.h4,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Heading 5',
          accessor: 'heading.h5',
          style: typography.heading.h5,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Heading 6',
          accessor: 'heading.h6',
          style: typography.heading.h6,
          foregroundColor: colors.foreground.main,
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Body Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Body Large',
          accessor: 'body.large',
          style: typography.body.large,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Body Large Medium',
          accessor: 'body.largeMedium',
          style: typography.body.largeMedium,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Body Regular',
          accessor: 'body.regular',
          style: typography.body.regular,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Body Medium',
          accessor: 'body.medium',
          style: typography.body.medium,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Body Small',
          accessor: 'body.small',
          style: typography.body.small,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Body Small Medium',
          accessor: 'body.smallMedium',
          style: typography.body.smallMedium,
          foregroundColor: colors.foreground.main,
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Label Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Caption',
          accessor: 'label.caption',
          style: typography.label.caption,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Caption Medium',
          accessor: 'label.captionMedium',
          style: typography.label.captionMedium,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Overline',
          accessor: 'label.overline',
          style: typography.label.overline,
          foregroundColor: colors.foreground.main,
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Button Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Button Large',
          accessor: 'button.large',
          style: typography.button.large,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Button Regular',
          accessor: 'button.regular',
          style: typography.button.regular,
          foregroundColor: colors.foreground.main,
        ),
        _TypographyItem(
          label: 'Button Small',
          accessor: 'button.small',
          style: typography.button.small,
          foregroundColor: colors.foreground.main,
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Code Styles', typography: typography),
        SizedBox(height: spacing.sm),
        _TypographyItem(
          label: 'Code Regular',
          accessor: 'code.regular',
          style: typography.code.regular,
          foregroundColor: colors.foreground.main,
          sampleText: 'const value = 42;',
        ),
        _TypographyItem(
          label: 'Code Small',
          accessor: 'code.small',
          style: typography.code.small,
          foregroundColor: colors.foreground.main,
          sampleText: 'const value = 42;',
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _SectionTitle({
  required final String title,
  required final PicoTypographyExtension typography,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(title, style: typography.heading.h5);
}

class const _TypographyItem({
  required final String label,
  required final String accessor,
  required final TextStyle style,
  required final Color foregroundColor,
  final String sampleText = 'The quick brown fox jumps over the lazy dog',
}) extends StatelessWidget {
  String get _fontWeightName {
    final weight = style.fontWeight;
    if (weight == null) return 'Regular';
    return switch (weight) {
      FontWeight.w100 => 'Thin',
      FontWeight.w200 => 'ExtraLight',
      FontWeight.w300 => 'Light',
      FontWeight.w400 => 'Regular',
      FontWeight.w500 => 'Medium',
      FontWeight.w600 => 'SemiBold',
      FontWeight.w700 => 'Bold',
      FontWeight.w800 => 'ExtraBold',
      FontWeight.w900 => 'Black',
      _ => 'Regular',
    };
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: typography.label.captionMedium),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  accessor,
                  style: typography.label.caption.copyWith(
                    color: colors.foreground.muted,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${style.fontSize?.toInt() ?? '-'}px',
                  style: typography.label.caption,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(_fontWeightName, style: typography.label.caption),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            sampleText,
            style: style.copyWith(color: foregroundColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.sm),
          Divider(color: colors.outline.subtle, height: 1),
        ],
      ),
    );
  }
}
