import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_merge_extension.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/product/presentation/cubit/product_details_state.dart';

class ProductDetailsCubit extends SafeCubit<ProductDetailsState> {
  ProductDetailsCubit(this._repository) : super(const ProductDetailsState());

  final ProductRepository _repository;
  static const int _pageSize = 10;

  Future<void> hydrate({
    required String hid,
    required ProductResCommon baseProduct,
    required int siteId,
  }) async {
    emit(
      state.copyWith(
        baseProduct: baseProduct,
        loading: true,
        relatedLoading: true,
        hasMoreRelated: true,
        relatedOffset: 0,
        relatedProducts: const <ProductResCommon>[],
        customerReviews: const [],
        imageIndex: 0,
        variantIndex: 0,
        clearError: true,
      ),
    );
    try {
      final product = await _repository.fetchProductDetails(hid);
      if (product == null) {
        throw const AppFailure(title: 'Product not found.');
      }
      final reviews = await _repository.FetchCustomerReview(product.id ?? 0, 16);
      final merged = baseProduct.mergeDetails(product);

      final categoryId = product.categories.isNotEmpty
          ? product.categories.first
          : null;
      final subCategoryId = product.subCategories.isNotEmpty
          ? product.subCategories.first
          : null;

      List<ProductResCommon> related = const <ProductResCommon>[];
      if (categoryId != null) {
        related = await _repository.fetchRelatedProducts(
          siteId,
          categoryId,
          subCategoryId,
          _pageSize,
          0,
        );
      }
      emit(
        state.copyWith(
          product: product,
          baseProduct: merged,
          customerReviews: reviews,
          relatedProducts: related,
          relatedOffset: related.length,
          hasMoreRelated: related.length >= _pageSize,
          loading: false,
          relatedLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          relatedLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load product details.',
          ),
        ),
      );
    }
  }

  Future<void> loadMoreRelated(int siteId) async {
    if (state.isFetchingMoreRelated ||
        !state.hasMoreRelated ||
        state.product == null) {
      return;
    }
    emit(state.copyWith(isFetchingMoreRelated: true));
    try {
      final product = state.product!;
      final categoryId = product.categories.isNotEmpty
          ? product.categories.first
          : null;
      final subCategoryId = product.subCategories.isNotEmpty
          ? product.subCategories.first
          : null;
      final items = await _repository.fetchRelatedProducts(
        siteId,
        categoryId,
        subCategoryId,
        _pageSize,
        state.relatedOffset,
      );
      emit(
        state.copyWith(
          relatedProducts: [...state.relatedProducts, ...items],
          relatedOffset: state.relatedOffset + items.length,
          hasMoreRelated: items.length >= _pageSize,
          isFetchingMoreRelated: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isFetchingMoreRelated: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load related products.',
          ),
        ),
      );
    }
  }

  Future<bool> submitReview(SubmitReviewReq model) async {
    final success = await _repository.makeCustomerReview(model);
    if (!success) return false;
    final productId = state.product?.id ?? 0;
    final reviews = await _repository.FetchCustomerReview(productId, 16);
    emit(state.copyWith(customerReviews: reviews));
    return true;
  }

  void setImageIndex(int value) => emit(state.copyWith(imageIndex: value));

  void setVariantIndex(int value) => emit(state.copyWith(variantIndex: value));

  bool isValidImage(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      return path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.webp');
    } catch (_) {
      return false;
    }
  }
}
