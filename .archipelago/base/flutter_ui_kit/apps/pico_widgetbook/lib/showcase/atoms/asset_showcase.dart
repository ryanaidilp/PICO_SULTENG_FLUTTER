import 'package:flutter/material.dart';
import 'package:pico_asset/pico_asset.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the asset widget showcase component for Widgetbook.
WidgetbookComponent assetShowcaseComponent() => WidgetbookComponent(
  name: 'Asset Widget',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoAssetWidget — Icon',
      builder: _buildIconAssetUseCase,
    ),
    WidgetbookUseCase(
      name: 'PicoAssetWidget — All Icons',
      builder: (context) => const _AllIconsShowcase(),
    ),
  ],
);

Widget _buildIconAssetUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 32,
    min: 16,
    max: 96,
    divisions: 10,
  );

  final useColor = context.knobs.boolean(label: 'Tint Color');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoAssetWidget.icon(
        PicoActionsIcons.search,
        size: size,
        color: useColor ? context.colors.action.primary.active : null,
      ),
    ),
  );
}

class const _AllIconsShowcase() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;

    final allIcons = <PicoIconAsset>[
      ...PicoActionsIcons.values,
      ...PicoArrowsIcons.values,
      ...PicoCommunicationIcons.values,
      ...PicoEssentialsIcons.values,
      ...PicoFeedbackIcons.values,
      ...PicoFilesIcons.values,
      ...PicoFinanceIcons.values,
      ...PicoMapsIcons.values,
      ...PicoMediaIcons.values,
      ...PicoSecurityIcons.values,
      ...PicoTimeIcons.values,
      ...PicoUsersIcons.values,
    ];

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        Text('Design System Icons', style: typography.heading.h5),
        SizedBox(height: spacing.md),
        Text(
          '${allIcons.length} icons across all categories',
          style: typography.body.small.copyWith(color: colors.foreground.muted),
        ),
        SizedBox(height: spacing.lg),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.md,
          children: allIcons.map((icon) => _IconTile(icon: icon)).toList(),
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _IconTile({required final PicoIconAsset icon})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final radius = context.radius;

    return Container(
      width: 72,
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: colors.background.subtle,
        borderRadius: radius.border.md,
        border: Border.all(color: colors.outline.subtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PicoAssetWidget.icon(icon, color: colors.foreground.main),
          SizedBox(height: spacing.xs),
          Text(
            icon.defaultSemanticLabel,
            style: typography.label.caption.copyWith(
              color: colors.foreground.subtle,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
