import 'package:flutter/material.dart';

enum OrderStatus {
  // Initial States
  pending('Pending', 'Your order has been placed and is being reviewed', Icons.receipt, Colors.orange),
  confirmed('Confirmed', 'Order confirmed and being prepared for pickup', Icons.check_circle, Colors.blue),

  // Driver Assignment & Pickup
  driverAssigned('Driver Assigned', 'A driver has been assigned to your order', Icons.person, Colors.purple),
  outForPickup('Out for Pickup', 'Driver is on the way to collect your items', Icons.local_shipping, Colors.indigo),
  reachedPickupLocation('Driver Arrived', 'Driver has arrived at your location', Icons.location_on, Colors.teal),
  pickedUp('Picked Up', 'Your items have been collected successfully', Icons.inventory_2, Colors.green),

  // Transit & Facility
  transitToFacility('In Transit', 'Your items are being transported to our facility', Icons.local_shipping, Colors.brown),
  arrivedAtFacility('At Facility', 'Your items have arrived at our processing facility', Icons.business, Colors.deepOrange),

  // Processing States
  sorting('Sorting', 'Sorting clothes by type and color for optimal processing', Icons.style, Colors.pink),
  washing('Washing', 'Washing in progress with premium detergents', Icons.local_laundry_service, Colors.cyan),
  drying('Drying', 'Industrial drying to ensure perfect moisture levels', Icons.dry_cleaning, Colors.amber),
  ironing('Ironing', 'Steam ironing for crisp, professional finish', Icons.iron, Colors.deepPurple),
  qualityCheck('Quality Check', 'Final inspection for freshness and quality assurance', Icons.verified, Colors.lightGreen),

  // Delivery Preparation
  readyForDelivery('Ready for Delivery', 'Your clothes are packed and ready for delivery', Icons.inventory, Colors.lime),
  outForDelivery('Out for Delivery', 'Driver is on the way to deliver your items', Icons.delivery_dining, Colors.green),
  reachedDeliveryLocation('Driver Arrived', 'Driver has arrived for delivery', Icons.location_on, Colors.teal),
  delivered('Delivered', 'Your clothes have been delivered successfully', Icons.home, Colors.green),

  // Completion
  completed('Completed', 'Order completed successfully. Thank you for using SwiftWash!', Icons.done_all, Colors.green),

  // Issue States
  cancelled('Cancelled', 'Order has been cancelled', Icons.cancel, Colors.red),
  pickupFailed('Pickup Failed', 'Unable to collect items. Please contact support', Icons.error, Colors.red),
  deliveryFailed('Delivery Failed', 'Unable to deliver. Please contact support', Icons.error, Colors.red),
  issueReported('Issue Reported', 'An issue has been reported with your order', Icons.report_problem, Colors.orange);

  const OrderStatus(this.displayName, this.description, this.icon, this.color);

  final String displayName;
  final String description;
  final IconData icon;
  final Color color;

  // Get next possible statuses
  List<OrderStatus> get nextPossibleStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.driverAssigned, OrderStatus.cancelled];
      case OrderStatus.driverAssigned:
        return [OrderStatus.outForPickup, OrderStatus.cancelled];
      case OrderStatus.outForPickup:
        return [OrderStatus.reachedPickupLocation, OrderStatus.pickupFailed];
      case OrderStatus.reachedPickupLocation:
        return [OrderStatus.pickedUp, OrderStatus.pickupFailed];
      case OrderStatus.pickedUp:
        return [OrderStatus.transitToFacility];
      case OrderStatus.transitToFacility:
        return [OrderStatus.arrivedAtFacility];
      case OrderStatus.arrivedAtFacility:
        return [OrderStatus.sorting];
      case OrderStatus.sorting:
        return [OrderStatus.washing];
      case OrderStatus.washing:
        return [OrderStatus.drying];
      case OrderStatus.drying:
        return [OrderStatus.ironing];
      case OrderStatus.ironing:
        return [OrderStatus.qualityCheck];
      case OrderStatus.qualityCheck:
        return [OrderStatus.readyForDelivery, OrderStatus.sorting]; // Can go back for rework
      case OrderStatus.readyForDelivery:
        return [OrderStatus.outForDelivery];
      case OrderStatus.outForDelivery:
        return [OrderStatus.reachedDeliveryLocation, OrderStatus.deliveryFailed];
      case OrderStatus.reachedDeliveryLocation:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
        return [OrderStatus.completed];
      default:
        return [];
    }
  }

  // Check if status allows customer actions
  bool get allowsCustomerActions {
    return [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.driverAssigned,
      OrderStatus.outForPickup,
      OrderStatus.reachedPickupLocation,
      OrderStatus.pickedUp,
      OrderStatus.transitToFacility,
      OrderStatus.arrivedAtFacility,
      OrderStatus.sorting,
      OrderStatus.washing,
      OrderStatus.drying,
      OrderStatus.ironing,
      OrderStatus.qualityCheck,
      OrderStatus.readyForDelivery,
      OrderStatus.outForDelivery,
      OrderStatus.reachedDeliveryLocation,
      OrderStatus.delivered,
    ].contains(this);
  }

  // Check if status shows tracking map
  bool get showsTrackingMap {
    return [
      OrderStatus.outForPickup,
      OrderStatus.reachedPickupLocation,
      OrderStatus.pickedUp,
      OrderStatus.transitToFacility,
      OrderStatus.outForDelivery,
      OrderStatus.reachedDeliveryLocation,
    ].contains(this);
  }

  // Get status progress (0.0 to 1.0)
  double get progress {
    const statusProgress = {
      OrderStatus.pending: 0.0,
      OrderStatus.confirmed: 0.1,
      OrderStatus.driverAssigned: 0.2,
      OrderStatus.outForPickup: 0.3,
      OrderStatus.reachedPickupLocation: 0.35,
      OrderStatus.pickedUp: 0.4,
      OrderStatus.transitToFacility: 0.5,
      OrderStatus.arrivedAtFacility: 0.55,
      OrderStatus.sorting: 0.6,
      OrderStatus.washing: 0.65,
      OrderStatus.drying: 0.7,
      OrderStatus.ironing: 0.75,
      OrderStatus.qualityCheck: 0.8,
      OrderStatus.readyForDelivery: 0.85,
      OrderStatus.outForDelivery: 0.9,
      OrderStatus.reachedDeliveryLocation: 0.95,
      OrderStatus.delivered: 0.98,
      OrderStatus.completed: 1.0,
    };
    return statusProgress[this] ?? 0.0;
  }

  // Get ETA based on status
  String get estimatedTimeRemaining {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return '30-45 mins';
      case OrderStatus.driverAssigned:
      case OrderStatus.outForPickup:
        return '20-30 mins';
      case OrderStatus.reachedPickupLocation:
        return '5-10 mins';
      case OrderStatus.pickedUp:
      case OrderStatus.transitToFacility:
        return '15-25 mins';
      case OrderStatus.arrivedAtFacility:
      case OrderStatus.sorting:
      case OrderStatus.washing:
      case OrderStatus.drying:
      case OrderStatus.ironing:
      case OrderStatus.qualityCheck:
        return '2-4 hours';
      case OrderStatus.readyForDelivery:
      case OrderStatus.outForDelivery:
        return '30-45 mins';
      case OrderStatus.reachedDeliveryLocation:
        return '5-10 mins';
      default:
        return 'Completed';
    }
  }

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == status.toLowerCase().replaceAll(' ', '').replaceAll('_', ''),
      orElse: () => OrderStatus.pending,
    );
  }
}
