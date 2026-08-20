import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_details.dart'
    hide Feature;
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';

class SellHubCatalogSeed {
  SellHubCatalogSeed._();

  static final DateTime _now = DateTime(2026, 4, 1, 10, 30);
  static final _GeneratedCatalog _generated = _GeneratedCatalog.build(_now);

  static final List<Map<String, dynamic>> suppliers = _generated.suppliers;
  static final List<CategoriesRes> categories = _generated.categories;
  static final List<SubCategoryRes> subCategories = _generated.subCategories;
  static final List<TopBrandRes> brands = _generated.brands;
  static final List<SiteSliderRes> sliders = _generated.sliders;
  static final List<SiteInformationRes> siteInfo = _generated.siteInfo;
  static final List<ProductResCommon> products = _generated.products;

  static final Map<String, ProductDetailsRes> productDetailsByHid = {
    for (final product in products) product.hid!: _detail(product),
  };

  static int? categoryIdForProduct(ProductResCommon product) =>
      _generated.productCategoryIds[product.id];

  static int? subCategoryIdForProduct(ProductResCommon product) =>
      _generated.productSubCategoryIds[product.id];

  static bool isNewProduct(ProductResCommon product) =>
      _generated.newProductIds.contains(product.id);

  static ProductDetailsRes _detail(ProductResCommon product) {
    return ProductDetailsRes.fromJson(<String, dynamic>{
      'affiliateCommission': 0.0,
      'affiliateCommissionPercentage': 0.0,
      'authors': const <dynamic>[],
      'barcode': 'BAR${product.id}',
      'brands': product.brands,
      'campaigns': const <dynamic>[],
      'cashback': 0.0,
      'categories': <int>[
        if (categoryIdForProduct(product) != null)
          categoryIdForProduct(product)!,
      ],
      'childProducts': const <dynamic>[],
      'collections': const <dynamic>[],
      'comparePrice': product.comparePrice,
      'cost': product.wholesalePrice,
      'createdAt': _now.toIso8601String(),
      'createdById': 1,
      'currency': product.currency,
      'deliveryCharge': product.deliveryCharge,
      'deliveryTime': 2,
      'description':
          '${product.title} is ready for fast reseller discovery with margin-safe pricing and supplier-backed fulfillment.',
      'discount': product.discount,
      'emiDuration': 0,
      'emiInterest': 0.0,
      'emiPrice': 0.0,
      'extraImages': const <dynamic>[],
      'faq': const <dynamic>[
        <String, dynamic>{
          'id': 1,
          'key': 'How fast is delivery?',
          'value':
              'Most supplier orders dispatch within 24 hours for Dhaka and major city delivery.',
        },
      ],
      'features': product.features.map((item) => item.toJson()).toList(),
      'file': null,
      'fileType': null,
      'flashPrice': product.flashPrice,
      'id': product.id,
      'hid': product.hid,
      'image': product.thumbnail,
      'images': product.images.map((item) => item.toJson()).toList(),
      'isActive': product.isActive,
      'isCod': true,
      'isContinueSelling': product.isContinueSelling,
      'isEmi': false,
      'isExclusive': product.isExclusive,
      'isFeatured': true,
      'isFlash': product.isFlash,
      'isNegotiable': product.isNegotiable,
      'isNew': isNewProduct(product),
      'isOneTime': product.isOneTime,
      'isPrivate': false,
      'isResell': true,
      'isTrack': true,
      'isVariant': false,
      'isWarranty': false,
      'keyword': product.title,
      'maxOrder': product.maxOrder,
      'maxResellPrice': product.maxResellPrice,
      'minResellPrice': product.minResellPrice,
      'metaDescription': product.title,
      'metaTitle': product.title,
      'minOrder': product.minOrder,
      'note': const <dynamic>[],
      'parentId': null,
      'price': product.price,
      'priority': 1,
      'productType': product.productType,
      'quantity': product.quantity,
      'requirements': const <dynamic>[],
      'rewardPoints': 0.0,
      'salePrice': product.price,
      'shops': const <dynamic>[],
      'siteId': product.siteId,
      'sku': product.sku,
      'slug': product.slug,
      'sold': (((product.ratingTotal ?? 0) * 2) + ((product.id ?? 0) % 90))
          .toDouble(),
      'source': 'local_seed',
      'stoppages': const <dynamic>[],
      'subCategories': <int>[
        if (subCategoryIdForProduct(product) != null)
          subCategoryIdForProduct(product)!,
      ],
      'subSubCategories': const <dynamic>[],
      'supplierId': product.siteId,
      'tags': const <dynamic>[],
      'thumbnail': product.thumbnail,
      'title': product.title,
      'translation': product.translation,
      'unit': 1.0,
      'unitType': 1,
      'updatedAt': _now.toIso8601String(),
      'updatedById': 1,
      'validFor': 365,
      'vat': 0.0,
      'variants': const <dynamic>[],
      'vouchers': const <dynamic>[],
      'warranty': null,
      'weight': product.weight,
      'wholesale': const <dynamic>[],
      'wholesalePrice': product.wholesalePrice,
      'wholesalePricePercentage': 0.0,
    });
  }
}

const _fashionCategory = _CategorySeed(
  title: 'Fashion',
  subTitles: <String>['T-Shirts', 'Shirts', 'Panjabi'],
  descriptors: <String>[
    'Oversized',
    'Premium',
    'Everyday',
    'Soft Touch',
    'Relaxed',
    'Classic',
  ],
  basePrice: 620,
  imagePool: <String>[
    'https://images.pexels.com/photos/6311392/pexels-photo-6311392.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/7679720/pexels-photo-7679720.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/9558567/pexels-photo-9558567.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _bagsCategory = _CategorySeed(
  title: 'Bags',
  subTitles: <String>['Tote Bags', 'Backpacks', 'Wallets'],
  descriptors: <String>[
    'Canvas',
    'Smart',
    'Travel',
    'Everyday',
    'Compact',
    'Minimal',
  ],
  basePrice: 880,
  imagePool: <String>[
    'https://images.pexels.com/photos/5704832/pexels-photo-5704832.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/2081199/pexels-photo-2081199.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/1152077/pexels-photo-1152077.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _homeCategory = _CategorySeed(
  title: 'Home Living',
  subTitles: <String>['Lamps', 'Bedding', 'Decor'],
  descriptors: <String>[
    'Minimal',
    'Warm Glow',
    'Modern',
    'Space Saver',
    'Premium',
    'Easy Home',
  ],
  basePrice: 1250,
  imagePool: <String>[
    'https://images.pexels.com/photos/1112598/pexels-photo-1112598.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/276583/pexels-photo-276583.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/6444367/pexels-photo-6444367.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _kitchenCategory = _CategorySeed(
  title: 'Kitchen',
  subTitles: <String>['Storage', 'Cookware', 'Dining'],
  descriptors: <String>[
    'Stackable',
    'Daily Cook',
    'Family',
    'Compact',
    'Fresh Lock',
    'Smart Kitchen',
  ],
  basePrice: 930,
  imagePool: <String>[
    'https://images.pexels.com/photos/4226796/pexels-photo-4226796.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/6996093/pexels-photo-6996093.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/6270548/pexels-photo-6270548.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _beautyCategory = _CategorySeed(
  title: 'Beauty',
  subTitles: <String>['Lip Color', 'Makeup', 'Nail Care'],
  descriptors: <String>[
    'Velvet',
    'Matte',
    'Radiant',
    'Soft Blend',
    'Studio',
    'Daily Glow',
  ],
  basePrice: 480,
  imagePool: <String>[
    'https://images.pexels.com/photos/2533266/pexels-photo-2533266.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/3373744/pexels-photo-3373744.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/2113855/pexels-photo-2113855.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _skincareCategory = _CategorySeed(
  title: 'Skin Care',
  subTitles: <String>['Serum', 'Face Wash', 'Sunscreen'],
  descriptors: <String>[
    'Brightening',
    'Daily Care',
    'Fresh Skin',
    'Hydra',
    'Calm',
    'Pure Glow',
  ],
  basePrice: 840,
  imagePool: <String>[
    'https://images.pexels.com/photos/6621338/pexels-photo-6621338.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/4465824/pexels-photo-4465824.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/6621143/pexels-photo-6621143.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _gadgetsCategory = _CategorySeed(
  title: 'Gadgets',
  subTitles: <String>['Smart Gadgets', 'Power Gear', 'Audio'],
  descriptors: <String>[
    'Smart',
    'Portable',
    'Fast Charge',
    'Pro',
    'Everyday Tech',
    'Lite',
  ],
  basePrice: 1480,
  imagePool: <String>[
    'https://images.pexels.com/photos/1037992/pexels-photo-1037992.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _mobileCategory = _CategorySeed(
  title: 'Mobile Accessories',
  subTitles: <String>['Cases', 'Earbuds', 'Cables'],
  descriptors: <String>[
    'Shockproof',
    'Bass Boost',
    'Fast Sync',
    'Slim',
    'Magnetic',
    'Daily Use',
  ],
  basePrice: 620,
  imagePool: <String>[
    'https://images.pexels.com/photos/4526414/pexels-photo-4526414.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/4526407/pexels-photo-4526407.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/4526406/pexels-photo-4526406.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _kidsCategory = _CategorySeed(
  title: 'Kids',
  subTitles: <String>['Baby Wear', 'Boys Wear', 'Girls Wear'],
  descriptors: <String>[
    'Soft Cotton',
    'Play Day',
    'Comfy',
    'School Ready',
    'Mini',
    'Happy Kids',
  ],
  basePrice: 540,
  imagePool: <String>[
    'https://images.pexels.com/photos/3662667/pexels-photo-3662667.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/1620760/pexels-photo-1620760.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/1257110/pexels-photo-1257110.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _toysCategory = _CategorySeed(
  title: 'Toys',
  subTitles: <String>['Learning Toys', 'Plush Toys', 'Activity Toys'],
  descriptors: <String>[
    'STEM',
    'Color Play',
    'Creative',
    'Fun Time',
    'Early Learn',
    'Happy Play',
  ],
  basePrice: 430,
  imagePool: <String>[
    'https://images.pexels.com/photos/3662669/pexels-photo-3662669.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/163036/mario-luigi-yoschi-figures-163036.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/3933025/pexels-photo-3933025.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _fitnessCategory = _CategorySeed(
  title: 'Fitness',
  subTitles: <String>['Yoga Gear', 'Gym Accessories', 'Recovery Tools'],
  descriptors: <String>[
    'Core',
    'Flex',
    'Active',
    'Move Easy',
    'Power',
    'Daily Fit',
  ],
  basePrice: 760,
  imagePool: <String>[
    'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/4498606/pexels-photo-4498606.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/6456308/pexels-photo-6456308.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);
const _officeCategory = _CategorySeed(
  title: 'Office Essentials',
  subTitles: <String>['Desk Setup', 'Stationery', 'Organizers'],
  descriptors: <String>[
    'Focus',
    'Desk Flow',
    'Workday',
    'Minimal',
    'Productive',
    'Clean Setup',
  ],
  basePrice: 510,
  imagePool: <String>[
    'https://images.pexels.com/photos/7974/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/669615/pexels-photo-669615.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/4145190/pexels-photo-4145190.jpeg?auto=compress&cs=tinysrgb&w=600',
  ],
);

class _GeneratedCatalog {
  const _GeneratedCatalog({
    required this.suppliers,
    required this.categories,
    required this.subCategories,
    required this.brands,
    required this.sliders,
    required this.siteInfo,
    required this.products,
    required this.productCategoryIds,
    required this.productSubCategoryIds,
    required this.newProductIds,
  });

  final List<Map<String, dynamic>> suppliers;
  final List<CategoriesRes> categories;
  final List<SubCategoryRes> subCategories;
  final List<TopBrandRes> brands;
  final List<SiteSliderRes> sliders;
  final List<SiteInformationRes> siteInfo;
  final List<ProductResCommon> products;
  final Map<int, int> productCategoryIds;
  final Map<int, int> productSubCategoryIds;
  final Set<int> newProductIds;

  factory _GeneratedCatalog.build(DateTime now) {
    const styles = <String>[
      'Edition',
      'Pick',
      'Drop',
      'Bundle',
      'Series',
      'Set',
      'Collection',
    ];
    final supplierSeeds = <_SupplierSeed>[
      const _SupplierSeed(
        siteId: 1001,
        domain: 'urbanwear.bponi.com',
        title: 'Urban Wear House',
        address: 'Mirpur DOHS, Dhaka',
        logo:
            'https://images.pexels.com/photos/1884584/pexels-photo-1884584.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Urban Layer', 'Street Loom', 'Mono Stitch'],
        categories: <_CategorySeed>[
          _fashionCategory,
          _bagsCategory,
          _mobileCategory,
          _beautyCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1002,
        domain: 'homeglow.bponi.com',
        title: 'HomeGlow BD',
        address: 'GEC Circle, Chattogram',
        logo:
            'https://images.pexels.com/photos/3965545/pexels-photo-3965545.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['GlowNest', 'Roomora', 'Daily Habitat'],
        categories: <_CategorySeed>[
          _homeCategory,
          _kitchenCategory,
          _officeCategory,
          _fitnessCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1003,
        domain: 'beautylane.bponi.com',
        title: 'Beauty Lane Wholesale',
        address: 'Dhanmondi 27, Dhaka',
        logo:
            'https://images.pexels.com/photos/3373725/pexels-photo-3373725.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Lumi Skin', 'Glow Theory', 'Velvet Bloom'],
        categories: <_CategorySeed>[
          _beautyCategory,
          _skincareCategory,
          _fashionCategory,
          _bagsCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1004,
        domain: 'gadgetharbor.bponi.com',
        title: 'Gadget Harbor',
        address: 'Banani 11, Dhaka',
        logo:
            'https://images.pexels.com/photos/1037992/pexels-photo-1037992.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['VoltEdge', 'Pixel Dock', 'Charge Craft'],
        categories: <_CategorySeed>[
          _gadgetsCategory,
          _mobileCategory,
          _officeCategory,
          _fitnessCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1005,
        domain: 'babynest.bponi.com',
        title: 'BabyNest Mart',
        address: 'Uttara Sector 7, Dhaka',
        logo:
            'https://images.pexels.com/photos/3662667/pexels-photo-3662667.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Tiny Trail', 'Little Orbit', 'Happy Sprout'],
        categories: <_CategorySeed>[
          _kidsCategory,
          _toysCategory,
          _beautyCategory,
          _homeCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1006,
        domain: 'fitfuel.bponi.com',
        title: 'FitFuel Market',
        address: 'Khilgaon, Dhaka',
        logo:
            'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Core Pulse', 'Flex Forge', 'Move Mode'],
        categories: <_CategorySeed>[
          _fitnessCategory,
          _gadgetsCategory,
          _mobileCategory,
          _fashionCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1007,
        domain: 'puredaily.bponi.com',
        title: 'PureDaily Essentials',
        address: 'Sylhet Zindabazar',
        logo:
            'https://images.pexels.com/photos/3965548/pexels-photo-3965548.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['PureDaily', 'Clean Loop', 'Fresh Habit'],
        categories: <_CategorySeed>[
          _homeCategory,
          _kitchenCategory,
          _beautyCategory,
          _skincareCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1008,
        domain: 'modestliving.bponi.com',
        title: 'Modest Living BD',
        address: 'Bashundhara R/A, Dhaka',
        logo:
            'https://images.pexels.com/photos/5816307/pexels-photo-5816307.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Noble Thread', 'Calm Ritual', 'Noor Living'],
        categories: <_CategorySeed>[
          _fashionCategory,
          _homeCategory,
          _bagsCategory,
          _officeCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1009,
        domain: 'officecraft.bponi.com',
        title: 'OfficeCraft Supply',
        address: 'Agrabad, Chattogram',
        logo:
            'https://images.pexels.com/photos/7974/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Desk Atlas', 'Paper Pilot', 'Workgrid'],
        categories: <_CategorySeed>[
          _officeCategory,
          _gadgetsCategory,
          _mobileCategory,
          _homeCategory,
        ],
      ),
      const _SupplierSeed(
        siteId: 1010,
        domain: 'travelcarry.bponi.com',
        title: 'TravelCarry Hub',
        address: 'Cox\'s Bazar Link Road',
        logo:
            'https://images.pexels.com/photos/346748/pexels-photo-346748.jpeg?auto=compress&cs=tinysrgb&w=300',
        brands: <String>['Carry Crew', 'Trip Loom', 'Move Lite'],
        categories: <_CategorySeed>[
          _bagsCategory,
          _fashionCategory,
          _mobileCategory,
          _gadgetsCategory,
        ],
      ),
    ];

    final suppliers = <Map<String, dynamic>>[];
    final categories = <CategoriesRes>[];
    final subCategories = <SubCategoryRes>[];
    final brands = <TopBrandRes>[];
    final sliders = <SiteSliderRes>[];
    final siteInfo = <SiteInformationRes>[];
    final products = <ProductResCommon>[];
    final productCategoryIds = <int, int>{};
    final productSubCategoryIds = <int, int>{};
    final newProductIds = <int>{};

    var nextProductId = 700001;
    var nextBrandId = 5001;
    var nextSliderId = 9001;

    for (
      var supplierIndex = 0;
      supplierIndex < supplierSeeds.length;
      supplierIndex++
    ) {
      final supplier = supplierSeeds[supplierIndex];
      suppliers.add(
        _supplier(
          siteId: supplier.siteId,
          domain: supplier.domain,
          title: supplier.title,
          address: supplier.address,
          logo: supplier.logo,
        ),
      );
      siteInfo.add(
        _site(
          siteId: supplier.siteId,
          domain: supplier.domain,
          title: supplier.title,
          address: supplier.address,
          logo: supplier.logo,
          now: now,
        ),
      );
      for (final brandTitle in supplier.brands) {
        brands.add(
          _brand(
            id: nextBrandId++,
            siteId: supplier.siteId,
            title: brandTitle,
            image: supplier.logo,
            now: now,
          ),
        );
      }
      sliders.add(
        _slider(
          id: nextSliderId++,
          siteId: supplier.siteId,
          title: '${supplier.title} hot picks',
          body: 'Fast-moving products from ${supplier.title}',
          cover: supplier.categories.first.imagePool.first,
          now: now,
        ),
      );
      sliders.add(
        _slider(
          id: nextSliderId++,
          siteId: supplier.siteId,
          title: '${supplier.title} margin picks',
          body: 'Profit-friendly products ready to resell',
          cover: supplier.categories.last.imagePool.last,
          now: now,
        ),
      );

      for (
        var categoryIndex = 0;
        categoryIndex < supplier.categories.length;
        categoryIndex++
      ) {
        final categorySeed = supplier.categories[categoryIndex];
        final categoryId = (supplier.siteId * 100) + categoryIndex + 1;
        categories.add(
          _category(
            id: categoryId,
            siteId: supplier.siteId,
            title: categorySeed.title,
            total: categorySeed.subTitles.length * 9,
            image: categorySeed.imagePool.first,
            cover:
                categorySeed.imagePool[(supplierIndex + categoryIndex) %
                    categorySeed.imagePool.length],
            now: now,
          ),
        );
        for (
          var subIndex = 0;
          subIndex < categorySeed.subTitles.length;
          subIndex++
        ) {
          final subTitle = categorySeed.subTitles[subIndex];
          final subCategoryId = (categoryId * 10) + subIndex + 1;
          subCategories.add(
            _subCategory(
              id: subCategoryId,
              siteId: supplier.siteId,
              categoryId: categoryId,
              title: subTitle,
              image:
                  categorySeed.imagePool[(subIndex + supplierIndex) %
                      categorySeed.imagePool.length],
              now: now,
            ),
          );
          for (var productIndex = 0; productIndex < 9; productIndex++) {
            final productId = nextProductId++;
            final title =
                '${categorySeed.descriptors[(productIndex + subIndex) % categorySeed.descriptors.length]} '
                '$subTitle ${styles[(supplierIndex + productIndex) % styles.length]}';
            final price =
                (categorySeed.basePrice +
                        (subIndex * 90) +
                        (productIndex * 55) +
                        (supplierIndex * 12))
                    .toDouble();
            final comparePrice = price + 140 + ((productIndex % 3) * 50);
            final wholesalePrice = (price * 0.78).roundToDouble();
            final minResellPrice = (price * 0.96).roundToDouble();
            final maxResellPrice = (comparePrice * 1.08).roundToDouble();
            final isFlash =
                (productIndex % 4 == 0) ||
                ((productId + supplier.siteId) % 9 == 0);
            final isNew =
                productIndex < 2 || (subIndex == 0 && supplierIndex.isEven);
            final brand =
                supplier.brands[(categoryIndex + subIndex + productIndex) %
                    supplier.brands.length];
            final image =
                categorySeed.imagePool[(subIndex + productIndex) %
                    categorySeed.imagePool.length];
            final rating = 4.1 + ((productIndex + subIndex) % 6) * 0.12;
            final ratingTotal =
                28 + (productIndex * 14) + (categoryIndex * 9) + supplierIndex;

            products.add(
              _product(
                id: productId,
                siteId: supplier.siteId,
                hid: 'prd$productId',
                title: title,
                category: categorySeed.title,
                subCategory: subTitle,
                supplierTitle: supplier.title,
                image: image,
                price: price,
                comparePrice: comparePrice,
                wholesalePrice: wholesalePrice,
                minResellPrice: minResellPrice,
                maxResellPrice: maxResellPrice,
                isNew: isNew,
                isFlash: isFlash,
                brand: brand,
                rating: rating,
                ratingTotal: ratingTotal,
                quantity: 18 + ((productIndex + categoryIndex) % 20),
              ),
            );
            productCategoryIds[productId] = categoryId;
            productSubCategoryIds[productId] = subCategoryId;
            if (isNew) {
              newProductIds.add(productId);
            }
          }
        }
      }
    }

    return _GeneratedCatalog(
      suppliers: suppliers,
      categories: categories,
      subCategories: subCategories,
      brands: brands,
      sliders: sliders,
      siteInfo: siteInfo,
      products: products,
      productCategoryIds: productCategoryIds,
      productSubCategoryIds: productSubCategoryIds,
      newProductIds: newProductIds,
    );
  }
}

class _SupplierSeed {
  const _SupplierSeed({
    required this.siteId,
    required this.domain,
    required this.title,
    required this.address,
    required this.logo,
    required this.brands,
    required this.categories,
  });

  final int siteId;
  final String domain;
  final String title;
  final String address;
  final String logo;
  final List<String> brands;
  final List<_CategorySeed> categories;
}

class _CategorySeed {
  const _CategorySeed({
    required this.title,
    required this.subTitles,
    required this.descriptors,
    required this.basePrice,
    required this.imagePool,
  });

  final String title;
  final List<String> subTitles;
  final List<String> descriptors;
  final int basePrice;
  final List<String> imagePool;
}

Map<String, dynamic> _supplier({
  required int siteId,
  required String domain,
  required String title,
  required String address,
  required String logo,
}) {
  return <String, dynamic>{
    'id': siteId,
    'domain': domain,
    'title': title,
    'phoneLogo': logo,
    'coverImage': logo,
    'address': address,
    'latitude': 23.8,
    'longitude': 90.3,
    'whiteLabelUrl': null,
  };
}

CategoriesRes _category({
  required int id,
  required int siteId,
  required String title,
  required int total,
  required String image,
  required String cover,
  required DateTime now,
}) {
  return CategoriesRes(
    description: '$title category',
    createdAt: now,
    categoriesResExternal: null,
    id: id,
    hid: 'cat$id',
    image: image,
    cover: cover,
    isActive: true,
    isExternal: false,
    isParent: true,
    isPrivate: false,
    priority: 1,
    siteId: siteId,
    slug: title.toLowerCase().replaceAll(' ', '-'),
    title: title,
    total: total,
    translation: title,
    updatedAt: now,
  );
}

SubCategoryRes _subCategory({
  required int id,
  required int siteId,
  required int categoryId,
  required String title,
  required String image,
  required DateTime now,
}) {
  return SubCategoryRes(
    description: '$title picks',
    categoryId: categoryId,
    hid: 'sub$id',
    id: id,
    image: image,
    isActive: true,
    isPrivate: false,
    priority: 1,
    siteId: siteId,
    slug: title.toLowerCase().replaceAll(' ', '-'),
    title: title,
    translation: title,
    updatedAt: now,
  );
}

TopBrandRes _brand({
  required int id,
  required int siteId,
  required String title,
  required String image,
  required DateTime now,
}) {
  return TopBrandRes(
    description: '$title reseller line',
    hid: 'br$id',
    id: id,
    image: image,
    isActive: true,
    isPrivate: false,
    priority: 1,
    siteId: siteId,
    slug: title.toLowerCase().replaceAll(' ', '-'),
    title: title,
    translation: title,
    updatedAt: now,
  );
}

SiteSliderRes _slider({
  required int id,
  required int siteId,
  required String title,
  required String body,
  required String cover,
  required DateTime now,
}) {
  return SiteSliderRes(
    body: body,
    cover: cover,
    id: id,
    isActive: true,
    isPrivate: false,
    isPhone: true,
    priority: 1,
    siteId: siteId,
    title: title,
    updatedAt: now,
    url: '',
  );
}

SiteInformationRes _site({
  required int siteId,
  required String domain,
  required String title,
  required String address,
  required String logo,
  required DateTime now,
}) {
  return SiteInformationRes(
    address: address,
    coverImage: logo,
    createdAt: now,
    createdById: 1,
    currency: 'BDT',
    desktopLogo: logo,
    desktopTheme: null,
    domain: domain,
    email: 'support@$domain',
    favicon: logo,
    foot: null,
    hostname: domain,
    id: siteId,
    industry: 'commerce',
    latitude: 23.8,
    locale: 'bn_BD',
    longitude: 90.3,
    notice: 'Sell from your phone. We handle delivery.',
    phone: 8801700000000 + siteId,
    phoneLogo: logo,
    social: Social(
      facebook: 'https://facebook.com/$domain',
      instagram: '',
      twitter: '',
      youtube: '',
    ),
    street: address,
    title: title,
    subscription: 'starter',
    subscriptionFee: 0,
    theme: 'sellhub',
    version: 1,
    whiteLabel: null,
    whiteLabelUrl: null,
    withdraw: 0,
    createdBy: CreatedBy(
      address: address,
      avatar: logo,
      country: 50,
      currency: 'BDT',
      email: 'owner@$domain',
      firstName: title.split(' ').first,
      id: 1,
      isStaff: false,
      name: title,
      phone: 8801700000000 + siteId,
      username: domain,
    ),
  );
}

ProductResCommon _product({
  required int id,
  required int siteId,
  required String hid,
  required String title,
  required String category,
  required String subCategory,
  required String supplierTitle,
  required String image,
  required double price,
  required double comparePrice,
  required double wholesalePrice,
  required double minResellPrice,
  required double maxResellPrice,
  required bool isNew,
  required bool isFlash,
  required String brand,
  required double rating,
  required int ratingTotal,
  required int quantity,
}) {
  return ProductResCommon(
    affiliateCommission: 0,
    brands: <String>[brand],
    cashback: 0,
    comparePrice: comparePrice,
    currency: 'BDT',
    deliveryCharge: 80,
    discount: comparePrice - price,
    isExclusive: false,
    features: <Feature>[
      Feature(key: 'Category', value: category),
      Feature(key: 'Subcategory', value: subCategory),
      Feature(key: 'Supplier', value: supplierTitle),
      Feature(key: 'Source', value: 'Local Seed'),
      Feature(key: 'Launch', value: isNew ? 'New' : 'Core'),
    ],
    flashPrice: isFlash ? price - 40 : null,
    hid: hid,
    id: id,
    images: <ProductImage>[ProductImage(id: id, image: image)],
    isActive: true,
    isContinueSelling: true,
    isFlash: isFlash,
    isOneTime: false,
    isNegotiable: false,
    isVariant: false,
    maxOrder: 10,
    maxResellPrice: maxResellPrice,
    minResellPrice: minResellPrice,
    minOrder: 1,
    price: price,
    productType: 1,
    quantity: quantity.toDouble(),
    rating: rating,
    ratingTotal: ratingTotal,
    rewardPoints: 0,
    siteId: siteId,
    sku: 'SKU$id',
    slug: title.toLowerCase().replaceAll(' ', '-'),
    thumbnail: image,
    title: title,
    translation: title,
    unit: 1,
    unitType: 1,
    variants: const <Variant>[],
    vat: 0,
    weight: 0.3,
    wholesale: const <dynamic>[],
    wholesalePrice: wholesalePrice,
  );
}
