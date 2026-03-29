import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import '../../../data/models/product_details.dart';
import '../../../presentation/cubit/product_details_state.dart';

class smallImageListHorizontal extends StatelessWidget {
  const smallImageListHorizontal({
    super.key,
    required this.validImages,
    required this.product,
    required this.state,
    required this.onImageSelected,
  });

  final List<ProductDetailsImage> validImages;
  final ProductDetailsRes? product;
  final ProductDetailsState state;
  final ValueChanged<int> onImageSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: validImages.isEmpty
          ? Container(
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.text.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AppNetworkImage(
                  imageUrl: product?.image ?? product?.thumbnail,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: validImages.length,
              itemBuilder: (context, index) {
                final image = validImages[index].image;
                //print(image);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      onImageSelected(index);
                    },
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: state.imageIndex == index
                                ? AppColor.primary.withValues(alpha: 0.18)
                                : AppColor.text.withValues(alpha: 0.02),
                            blurRadius: state.imageIndex == index ? 10 : 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AppNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LargeImageProductDetails extends StatelessWidget {
  const LargeImageProductDetails({
    super.key,
    required this.visualCatalog,
    required this.validImages,
    required this.product,
    required this.state,
  });

  final bool visualCatalog;
  final List<ProductDetailsImage> validImages;
  final ProductDetailsRes? product;
  final ProductDetailsState state;

  @override
  Widget build(BuildContext context) {
    final imageUrl = validImages.isEmpty
        ? product?.image ?? product?.thumbnail
        : validImages[state.imageIndex].image;
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * (visualCatalog ? 0.48 : 0.38),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColor.text.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppNetworkImage(
                imageUrl: imageUrl,
                fit: visualCatalog ? BoxFit.cover : BoxFit.contain,
                backgroundColor: Colors.white,
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.text.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  visualCatalog ? 'Preview' : 'Image',
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
