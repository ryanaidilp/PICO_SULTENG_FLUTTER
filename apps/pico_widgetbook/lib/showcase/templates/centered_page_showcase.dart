import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the centered page template showcase component for Widgetbook.
WidgetbookComponent centeredPageShowcaseComponent() => WidgetbookComponent(
  name: 'CenteredPageTemplate',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoCenteredPageTemplate',
      builder: _buildPicoCenteredPageTemplateUseCase,
    ),
  ],
);

Widget _buildPicoCenteredPageTemplateUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Welcome Back',
  );

  final subtitle = context.knobs.string(
    label: 'Subtitle',
    initialValue: 'Sign in to continue to your account.',
  );

  final hasIcon = context.knobs.boolean(label: 'Has Icon', initialValue: true);

  final hasContent = context.knobs.boolean(
    label: 'Has Content',
    initialValue: true,
  );

  final hasActions = context.knobs.boolean(
    label: 'Has Actions',
    initialValue: true,
  );

  final scrollable = context.knobs.boolean(
    label: 'Scrollable',
    initialValue: true,
  );

  final crossAxisAlignment = context.knobs.object.dropdown<CrossAxisAlignment>(
    label: 'Alignment',
    options: [
      CrossAxisAlignment.center,
      CrossAxisAlignment.start,
      CrossAxisAlignment.stretch,
    ],
    initialOption: CrossAxisAlignment.center,
    labelBuilder: (a) => a.name,
  );

  return PicoCenteredPageTemplate(
    title: title.isEmpty ? null : title,
    subtitle: subtitle.isEmpty ? null : subtitle,
    scrollable: scrollable,
    crossAxisAlignment: crossAxisAlignment,
    icon: hasIcon
        ? Icon(Icons.lock_outline_rounded, size: 64, color: Colors.indigo[400])
        : null,
    content: hasContent ? const _ContentForm() : null,
    actions: hasActions
        ? [
            PicoButton(label: 'Sign In', isExpanded: true, onPressed: () {}),
            PicoButton(
              label: 'Create Account',
              style: PicoButtonStyle.outlined,
              isExpanded: true,
              onPressed: () {},
            ),
          ]
        : null,
  );
}

class const _ContentForm() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      PicoTextField(
        label: 'Email',
        hint: 'Enter your email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      SizedBox(height: 12),
      PicoTextField(
        label: 'Password',
        hint: 'Enter your password',
        obscureText: true,
        prefixIcon: Icon(Icons.lock_outline),
      ),
    ],
  );
}
