enum StoreIndustryKind { grocery, pharmacy, fashion, lifestyle, generic }

class StoreIndustry {
  const StoreIndustry._();

  static const Map<int, String> labelsById = <int, String>{
    1: 'Groceries',
    2: 'Fashion',
    19: 'Book',
    20: 'Book and Others',
    10: 'Beauty',
    3: 'Electronics',
    4: 'Furniture',
    5: 'Handcrafts',
    6: 'Jewelry',
    7: 'Painting',
    8: 'Photography',
    9: 'Restaurants',
    11: 'food and drink',
    12: 'Sports',
    13: 'Toys',
    14: 'Services',
    15: 'Virtual services',
    16: 'Course',
    17: 'Medicine',
    18: 'News',
    21: 'Personal and Portfolio',
    99: 'Other',
  };

  static const Map<int, StoreIndustryKind> kindById = <int, StoreIndustryKind>{
    1: StoreIndustryKind.grocery,
    11: StoreIndustryKind.grocery,
    17: StoreIndustryKind.pharmacy,
    2: StoreIndustryKind.fashion,
    10: StoreIndustryKind.lifestyle,
    5: StoreIndustryKind.lifestyle,
    6: StoreIndustryKind.lifestyle,
    7: StoreIndustryKind.lifestyle,
    8: StoreIndustryKind.lifestyle,
    19: StoreIndustryKind.generic,
    20: StoreIndustryKind.generic,
    3: StoreIndustryKind.generic,
    4: StoreIndustryKind.generic,
    9: StoreIndustryKind.generic,
    12: StoreIndustryKind.generic,
    13: StoreIndustryKind.generic,
    14: StoreIndustryKind.generic,
    15: StoreIndustryKind.generic,
    16: StoreIndustryKind.generic,
    18: StoreIndustryKind.generic,
    21: StoreIndustryKind.generic,
    99: StoreIndustryKind.generic,
  };

  static StoreIndustryKind fromRaw(Object? raw) {
    final industryId = parseId(raw);
    if (industryId != null) {
      return kindById[industryId] ?? StoreIndustryKind.generic;
    }

    final value = (raw?.toString() ?? '').trim().toLowerCase();
    if (value.isEmpty) return StoreIndustryKind.generic;

    final matchedId = labelsById.entries
        .where((entry) => entry.value.toLowerCase() == value)
        .map((entry) => entry.key)
        .cast<int?>()
        .firstWhere((entry) => entry != null, orElse: () => null);
    if (matchedId != null) {
      return kindById[matchedId] ?? StoreIndustryKind.generic;
    }

    return StoreIndustryKind.generic;
  }

  static int? parseId(Object? raw) {
    if (raw is num) return raw.toInt();
    final value = (raw?.toString() ?? '').trim();
    return int.tryParse(value);
  }

  static bool isDenseCatalog(StoreIndustryKind kind) {
    return kind == StoreIndustryKind.grocery ||
        kind == StoreIndustryKind.pharmacy;
  }

  static bool isVisualCatalog(StoreIndustryKind kind) {
    return kind == StoreIndustryKind.fashion ||
        kind == StoreIndustryKind.lifestyle;
  }
}
