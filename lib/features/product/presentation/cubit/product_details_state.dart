import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';
import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.product,
    this.baseProduct,
    this.relatedProducts = const <ProductResCommon>[],
    this.customerReviews = const <CustomerReviewResModel>[],
    this.imageIndex = 0,
    this.variantIndex = 0,
    this.loading = false,
    this.relatedLoading = false,
    this.isFetchingMoreRelated = false,
    this.hasMoreRelated = true,
    this.relatedOffset = 0,
    this.error,
    this.supplierTrust,
  });

  final ProductDetailsRes? product;
  final ProductResCommon? baseProduct;
  final List<ProductResCommon> relatedProducts;
  final List<CustomerReviewResModel> customerReviews;
  final int imageIndex;
  final int variantIndex;
  final bool loading;
  final bool relatedLoading;
  final bool isFetchingMoreRelated;
  final bool hasMoreRelated;
  final int relatedOffset;
  final AppFailure? error;
  final SupplierTrustProfile? supplierTrust;

  double get averageRating {
    if (customerReviews.isEmpty) return 0;
    final total = customerReviews.fold<int>(
      0,
      (sum, review) => sum + (review.rating ?? 0),
    );
    return total / customerReviews.length;
  }

  Map<int, int> get ratingBreakdown {
    final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in customerReviews) {
      final rating = review.rating ?? 0;
      if (rating >= 1 && rating <= 5) {
        breakdown[rating] = (breakdown[rating] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  double ratingPercent(int star) {
    if (customerReviews.isEmpty) return 0;
    return (ratingBreakdown[star] ?? 0) / customerReviews.length;
  }

  ProductDetailsState copyWith({
    ProductDetailsRes? product,
    ProductResCommon? baseProduct,
    List<ProductResCommon>? relatedProducts,
    List<CustomerReviewResModel>? customerReviews,
    int? imageIndex,
    int? variantIndex,
    bool? loading,
    bool? relatedLoading,
    bool? isFetchingMoreRelated,
    bool? hasMoreRelated,
    int? relatedOffset,
    AppFailure? error,
    SupplierTrustProfile? supplierTrust,
    bool clearError = false,
  }) {
    return ProductDetailsState(
      product: product ?? this.product,
      baseProduct: baseProduct ?? this.baseProduct,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      customerReviews: customerReviews ?? this.customerReviews,
      imageIndex: imageIndex ?? this.imageIndex,
      variantIndex: variantIndex ?? this.variantIndex,
      loading: loading ?? this.loading,
      relatedLoading: relatedLoading ?? this.relatedLoading,
      isFetchingMoreRelated:
          isFetchingMoreRelated ?? this.isFetchingMoreRelated,
      hasMoreRelated: hasMoreRelated ?? this.hasMoreRelated,
      relatedOffset: relatedOffset ?? this.relatedOffset,
      error: clearError ? null : error ?? this.error,
      supplierTrust: supplierTrust ?? this.supplierTrust,
    );
  }

  @override
  List<Object?> get props => [
    product,
    baseProduct,
    relatedProducts,
    customerReviews,
    imageIndex,
    variantIndex,
    loading,
    relatedLoading,
    isFetchingMoreRelated,
    hasMoreRelated,
    relatedOffset,
    error,
    supplierTrust,
  ];
}
