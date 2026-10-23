/// Represents the atomic design layers for UI components.
enum Layer(
  /// The directory name for this layer.
  final String directory,
) {
  /// Basic building blocks (buttons, inputs, icons).
  atom('atoms'),

  /// Simple groups of atoms (search bar, form field).
  molecule('molecules'),

  /// Complex UI sections (app bar, login form).
  organism('organisms'),

  /// Page-level layouts without real content.
  template('templates'),

  /// Templates with actual content.
  page('pages'),
}
