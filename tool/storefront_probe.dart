import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';
import 'package:sellhub/core/database/local_entity_database.dart';

Future<void> main() async {
  final db = LocalEntityDatabase();
  await db.initialize();
  final api = LocalGraphQLApi(database: db);
  final store = SellHubCatalogLocalStore(api: api);
  Future<void> probe(String label, Future<Object?> Function() fn) async {
    try {
      final value = await fn();
      if (value is List) {
        print('$label ok count=${value.length}');
      } else {
        print('$label ok value=$value');
      }
    } catch (e, st) {
      print('$label FAILED $e');
      print(st);
    }
  }

  await probe('categories', () => store.loadCategories(0));
  await probe('products', () => store.loadProducts(siteId: 0));
  await probe('sliders', () => store.loadSliders(0));
  await probe('brands', () => store.loadBrands(0));
  await probe('flash', () => store.loadProducts(siteId: 0, isFlash: true));
  await probe('new', () => store.loadProducts(siteId: 0, isNew: true));
}
