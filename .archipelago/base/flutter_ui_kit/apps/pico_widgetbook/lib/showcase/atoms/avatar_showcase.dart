import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the avatar showcase component for Widgetbook.
WidgetbookComponent avatarShowcaseComponent() => WidgetbookComponent(
  name: 'Avatars',
  useCases: [
    WidgetbookUseCase(name: 'PicoAvatar', builder: _buildPicoAvatarUseCase),
  ],
);

Widget _buildPicoAvatarUseCase(BuildContext context) {
  final size = context.knobs.object.dropdown<PicoAvatarSize>(
    label: 'Size',
    options: PicoAvatarSize.values,
    initialOption: PicoAvatarSize.md,
    labelBuilder: (size) => size.name,
  );

  final contentType = context.knobs.object.dropdown<_AvatarContentType>(
    label: 'Content Type',
    options: _AvatarContentType.values,
    initialOption: _AvatarContentType.initials,
    labelBuilder: (type) => type.name,
  );

  final initials = context.knobs.string(label: 'Initials', initialValue: 'JD');

  final hasBorder = context.knobs.boolean(label: 'Show Border');

  final isTappable = context.knobs.boolean(label: 'Tappable');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoAvatar(
        size: size,
        imageUrl: contentType == _AvatarContentType.image
            ? 'https://i.pravatar.cc/150?img=3'
            : null,
        initials: contentType == _AvatarContentType.initials ? initials : null,
        icon: contentType == _AvatarContentType.icon ? Icons.person : null,
        borderWidth: hasBorder ? 2 : null,
        onTap: isTappable ? () {} : null,
      ),
    ),
  );
}

/// Avatar content type for the use case.
enum _AvatarContentType() {
  /// Show image from URL.
  image,

  /// Show initials.
  initials,

  /// Show icon.
  icon,
}
