import 'package:sellhub/features/cart/data/checkout_repository.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';

class OrdersRepository {
  OrdersRepository(this._profileRepository, this._checkoutRepository);

  final ProfileRepository _profileRepository;
  final CheckoutRepository _checkoutRepository;

  Future<List<OrderHistoryResModelProfile>> fetchOrders({
    required int siteId,
    required int customerId,
  }) {
    return _profileRepository.fetchOrderHistory(siteId, customerId);
  }

  Future<List<OrderEventModel>> fetchOrderEvents({
    required int siteId,
    required int orderId,
  }) {
    return _checkoutRepository.fetchOrderEvents(
      siteId: siteId,
      orderId: orderId,
    );
  }

  Future<OrderEventModel> createCustomerOrderEvent({
    required int userId,
    required int siteId,
    required int orderId,
    required int eventType,
    required String note,
  }) {
    return _checkoutRepository.createCustomerOrderEvent(
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      eventType: eventType,
      note: note,
    );
  }
}
