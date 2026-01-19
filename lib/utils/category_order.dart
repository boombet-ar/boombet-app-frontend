import 'package:boombet_app/models/cupon_model.dart';

class CategoryOrder {
  static const List<String> preferredOrder = [
    'Compras',
    'Gastronomia',
    'Servicios',
    'Turismo',
    'Gimnasios y deportes',
    'Salud y belleza',
    'Indumentaria calzado y moda',
    'Educacion',
    'Entretenimientos',
    'Cines',
    'Teatros',
    'Autos',
    'Motos',
    'Inmuebles',
    'Inmobiliarias',
  ];

  static final Map<String, int> _priorityByKey = () {
    final map = <String, int>{};
    for (var i = 0; i < preferredOrder.length; i++) {
      map[_key(preferredOrder[i])] = i;
    }

    // Aliases comunes (singular/plural y variantes esperables del backend)
    map[_key('Gastronomía')] = map[_key('Gastronomia')]!;
    map[_key('Educación')] = map[_key('Educacion')]!;
    map[_key('Entretenimiento')] = map[_key('Entretenimientos')]!;
    map[_key('Cine')] = map[_key('Cines')]!;
    map[_key('Teatro')] = map[_key('Teatros')]!;
    map[_key('Auto')] = map[_key('Autos')]!;
    map[_key('Moto')] = map[_key('Motos')]!;
    map[_key('Inmueble')] = map[_key('Inmuebles')]!;
    map[_key('Inmobiliaria')] = map[_key('Inmobiliarias')]!;
    map[_key('Indumentaria, Calzado y Moda')] =
        map[_key('Indumentaria calzado y moda')]!;
    map[_key('Gimnasios y Deportes')] = map[_key('Gimnasios y deportes')]!;

    return map;
  }();

  static List<Categoria> sortCategorias(Iterable<Categoria> categorias) {
    final indexed = categorias.toList(growable: false).asMap().entries.toList();

    indexed.sort((a, b) {
      final ap = _priorityForName(a.value.nombre);
      final bp = _priorityForName(b.value.nombre);
      if (ap != bp) return ap.compareTo(bp);
      return a.key.compareTo(b.key);
    });

    return indexed.map((e) => e.value).toList(growable: false);
  }

  static List<String> sortCategoryNames(Iterable<String> names) {
    final indexed = names.toList(growable: false).asMap().entries.toList();

    indexed.sort((a, b) {
      final ap = _priorityForName(a.value);
      final bp = _priorityForName(b.value);
      if (ap != bp) return ap.compareTo(bp);
      return a.key.compareTo(b.key);
    });

    return indexed.map((e) => e.value).toList(growable: false);
  }

  static int _priorityForName(String name) {
    return _priorityByKey[_key(name)] ?? 1 << 30;
  }

  static String _key(String value) {
    var s = value.trim().toLowerCase();

    s = s
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');

    // Normaliza separadores y puntuación (comas, guiones, etc.).
    s = s.replaceAll(RegExp(r"[^a-z0-9]+"), ' ');
    s = s.replaceAll(RegExp(r"\s+"), ' ').trim();

    return s;
  }
}
