import 'package:flutter_test/flutter_test.dart';
import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/database/local_entity_database.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marketplace seed loads core storefront collections', () async {
    final database = LocalEntityDatabase();
    await database.initialize();
    final api = LocalGraphQLApi(database: database);
    final store = SellHubCatalogLocalStore(api: api);

    final categories = await store.loadCategories(0);
    final subCategories = await store.loadSubCategories(0);
    final products = await store.loadProducts(siteId: 0);
    final sliders = await store.loadSliders(0);
    final brands = await store.loadBrands(0);
    final flash = await store.loadProducts(siteId: 0, isFlash: true);
    final fresh = await store.loadProducts(siteId: 0, isNew: true);

    expect(categories, isNotEmpty);
    expect(
      categories.every((item) => (item.image?.isNotEmpty ?? false)),
      isTrue,
    );
    expect(
      categories.every((item) => (item.cover?.isNotEmpty ?? false)),
      isTrue,
    );
    expect(subCategories, isNotEmpty);
    expect(
      subCategories.every((item) => (item.image?.isNotEmpty ?? false)),
      isTrue,
    );
    expect(products, isNotEmpty);
    expect(sliders, isNotEmpty);
    expect(sliders.every((item) => (item.cover?.isNotEmpty ?? false)), isTrue);
    expect(brands, isNotEmpty);
    expect(flash, isNotEmpty);
    expect(fresh, isNotEmpty);
  });
}
