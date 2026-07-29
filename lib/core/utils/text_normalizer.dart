const Map<String, String> _accentMap = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n',
};

/// Normaliza texto para busqueda: minusculas y sin acentos, para que
/// "amoxicilina" encuentre "Amoxicilina" o "AMOXICILINA" indistintamente.
/// Ver docs/plan_de_trabajo.md - buscador "tolerante a acentos y mayusculas".
String normalizeForSearch(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString();
}
