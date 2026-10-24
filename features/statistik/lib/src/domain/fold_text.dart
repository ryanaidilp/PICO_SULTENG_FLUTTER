const _from = 'àáâãäåāăąèéêëēĕėęěìíîïĩīĭįòóôõöōŏőùúûüũūŭůűųñńçćčśšźžżýÿ';
const _to =
    'aaaaaaaaaeeeeeeeeeiiiiiiiioooooooouuuuuuuuuunnccc'
    'sszzzyy';

/// Lowercase [s] and drop common Latin accents, so a search for "sindhu" finds
/// "Sindhú" and "palu" finds "PALU".
String foldText(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = _from.indexOf(c);
    b.write(i >= 0 && i < _to.length ? _to[i] : c);
  }
  return b.toString();
}
