extension NewGetOrNullMap on Map<String, dynamic> {
  // Retrieve a map from the map safely
  Map<String, dynamic>? getMap(String key) {
    var value = this[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  // Retrieve a string from the map safely
  String? getString(String key) {
    var value = this[key];
    if (value is String) {
      return value;
    }
    return null;
  }

  // Retrieve a list from the map safely
  List<Map<String, dynamic>>? getList(String key) {
    var v = this[key];
    if (v == null) {
      return null;
    }
    if (v is! List<dynamic>) {
      throw Exception('Invalid type: ${v.runtimeType} should be of type List');
    }

    return (v.toList()).cast<Map<String, dynamic>>();
  }
}

extension ListUtil<E> on Iterable<E> {
  E? elementAtSafe(int index) {
    if (index >= length) {
      return null;
    }
    return elementAt(index);
  }
}
