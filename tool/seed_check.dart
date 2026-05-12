import 'package:sellhub/core/local_seed/sellhub_catalog_seed.dart';

void main() {
  print('suppliers=${SellHubCatalogSeed.suppliers.length}');
  print('categories=${SellHubCatalogSeed.categories.length}');
  print('subCategories=${SellHubCatalogSeed.subCategories.length}');
  print('brands=${SellHubCatalogSeed.brands.length}');
  print('sliders=${SellHubCatalogSeed.sliders.length}');
  print('products=${SellHubCatalogSeed.products.length}');
  final first = SellHubCatalogSeed.products.first;
  print('first=${first.title} site=${first.siteId} cat=${SellHubCatalogSeed.categoryIdForProduct(first)} sub=${SellHubCatalogSeed.subCategoryIdForProduct(first)}');
}
