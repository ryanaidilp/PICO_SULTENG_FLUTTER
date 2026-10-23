import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/buttons/pico_button.dart';
import 'package:pico_ui_kit/src/components/atoms/cards/pico_card.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// A molecule component for displaying product information.
///
/// Combines card, button, and typography atoms to create a complete
/// product display with image, title, price, description, and actions.
///
/// ```dart
/// PicoProductCard(
///   title: 'Product Name',
///   price: r'$99.99',
///   description: 'A great product.',
///   imageUrl: 'https://example.com/image.jpg',
///   onTap: () => Navigator.push(...),
///   onAddToCart: () => cart.add(product),
/// )
/// ```
class const PicoProductCard({
  /// The product title.
  required final String title,

  /// The product price.
  required final String price,

  /// Optional product image URL.
  final String? imageUrl,

  /// Optional product description.
  final String? description,

  /// Callback when the card is tapped.
  final VoidCallback? onTap,

  /// Callback when add to cart is pressed.
  final VoidCallback? onAddToCart,

  /// Label for the add to cart button.
  final String addToCartLabel = 'Add to Cart',

  /// Height of the product image.
  final double imageHeight = 150,

  /// Whether to show the add to cart button.
  final bool showAddToCartButton = true,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoProductCard].
  this;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;
    final appRadius = context.radius;

    return PicoCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product image
          _ProductImage(
            imageUrl: imageUrl,
            height: imageHeight,
            borderRadius: appRadius.circular.md,
            subtleColor: colors.background.subtle,
            mutedColor: colors.foreground.muted,
          ),
          // Product info
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: typography.heading.h6,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing.xs),
                // Price
                Text(
                  price,
                  style: typography.heading.h5.copyWith(
                    color: colors.action.primary.active,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Description
                if (description != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    description!,
                    style: typography.body.small.copyWith(
                      color: colors.foreground.subtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Add to Cart button
                if (showAddToCartButton && onAddToCart != null) ...[
                  SizedBox(height: spacing.md),
                  PicoButton(
                    label: addToCartLabel,
                    onPressed: onAddToCart,
                    size: PicoButtonSize.sm,
                    isExpanded: true,
                    leadingIcon: Icons.add_shopping_cart_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('price', price))
      ..add(StringProperty('imageUrl', imageUrl))
      ..add(StringProperty('description', description))
      ..add(StringProperty('addToCartLabel', addToCartLabel))
      ..add(DoubleProperty('imageHeight', imageHeight))
      ..add(
        DiagnosticsProperty<bool>('showAddToCartButton', showAddToCartButton),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onAddToCart', onAddToCart));
  }
}

/// Internal widget for displaying the product image.
class const _ProductImage({
  required final double height,
  required final Radius borderRadius,
  required final Color subtleColor,
  required final Color mutedColor,
  final String? imageUrl,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.only(
      topLeft: borderRadius,
      topRight: borderRadius,
    ),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _ImagePlaceholder(
                subtleColor: subtleColor,
                mutedColor: mutedColor,
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _ImagePlaceholder(
                  subtleColor: subtleColor,
                  mutedColor: mutedColor,
                  isLoading: true,
                );
              },
            )
          : _ImagePlaceholder(subtleColor: subtleColor, mutedColor: mutedColor),
    ),
  );
}

/// Placeholder widget shown when image is loading or unavailable.
class const _ImagePlaceholder({
  required final Color subtleColor,
  required final Color mutedColor,
  final bool isLoading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: subtleColor,
    child: Center(
      child: isLoading
          ? CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(mutedColor),
            )
          : Icon(Icons.image_outlined, size: 48, color: mutedColor),
    ),
  );
}
