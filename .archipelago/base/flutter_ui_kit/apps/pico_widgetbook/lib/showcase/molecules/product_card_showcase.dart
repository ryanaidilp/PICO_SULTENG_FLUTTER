import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the product card showcase component for Widgetbook.
WidgetbookComponent productCardShowcaseComponent() => WidgetbookComponent(
  name: 'ProductCard',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoProductCard',
      builder: _buildPicoProductCardUseCase,
    ),
  ],
);

Widget _buildPicoProductCardUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Wireless Headphones',
  );

  final price = context.knobs.string(label: 'Price', initialValue: r'$99.99');

  final description = context.knobs.string(
    label: 'Description',
    initialValue: 'Premium noise-cancelling headphones with 30-hour battery.',
  );

  final hasImage = context.knobs.boolean(label: 'Has Image');

  final showAddToCart = context.knobs.boolean(
    label: 'Show Add to Cart',
    initialValue: true,
  );

  final addToCartLabel = context.knobs.string(
    label: 'Add to Cart Label',
    initialValue: 'Add to Cart',
  );

  final imageHeight = context.knobs.double.slider(
    label: 'Image Height',
    initialValue: 150,
    min: 80,
    max: 250,
  );

  final isTappable = context.knobs.boolean(label: 'Tappable');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 260,
        child: PicoProductCard(
          title: title,
          price: price,
          description: description,
          imageUrl: hasImage
              ? 'https://picsum.photos/seed/product/400/300'
              : null,
          imageHeight: imageHeight,
          showAddToCartButton: showAddToCart,
          addToCartLabel: addToCartLabel,
          onTap: isTappable ? () {} : null,
          onAddToCart: showAddToCart ? () {} : null,
        ),
      ),
    ),
  );
}
