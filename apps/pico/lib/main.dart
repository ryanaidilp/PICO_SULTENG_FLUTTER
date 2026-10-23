import 'package:pico/app.dart';
import 'package:pico/bootstrap.dart';

// archipelago:imports:start
// archipelago:imports:end

void main() => bootstrap(
  flavor: 'production',
  builder: (result) => PicoApp(router: result.requireRouter),
);
