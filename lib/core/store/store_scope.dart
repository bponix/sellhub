import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class StoreScope {
  const StoreScope._();

  static int siteIdFromState(StorefrontState state) =>
      state.siteDetails?.id ?? StoreRegistry.currentStore?.siteId ?? 0;

  static String domainFromState(StorefrontState state) =>
      state.siteDetails?.domain?.trim().isNotEmpty == true
      ? state.siteDetails!.domain!.trim()
      : (StoreRegistry.currentStore?.domain ?? 'sellhub.bponi.com');

  static int sourceIdFromState(StorefrontState state) =>
      state.siteDetails?.createdById ??
      state.siteDetails?.createdBy?.id ??
      state.siteDetails?.id ??
      StoreRegistry.currentStore?.siteId ??
      1;

  static int activeSiteId(BuildContext context) {
    final storefront = context.read<StorefrontCubit>().state;
    return siteIdFromState(storefront);
  }

  static String activeDomain(BuildContext context) {
    final storefront = context.read<StorefrontCubit>().state;
    return domainFromState(storefront);
  }

  static int activeSourceId(BuildContext context) {
    final storefront = context.read<StorefrontCubit>().state;
    return sourceIdFromState(storefront);
  }
}
