import 'package:flutter/material.dart';

enum OrderStatus {
  pending('Pending', 'Order received, waiting for confirmation', Icons.schedule, Colors.orange),
  confirmed('Confirmed', 'Order confirmed by operator', Icons.check_circle, Colors.blue),
  driverAssigned('Driver Assigned', 'Driver assigned to order', Icons.person, Colors.purple),
  outForPickup('Out for Pickup', 'Driver on the way to pickup', Icons.local_shipping, Colors.indigo),
  reachedPickupLocation('Reached Pickup', 'Driver arrived at pickup location', Icons.location_on, Colors.teal),
  pickedUp('Picked Up', 'Items collected from customer', Icons.shopping_bag, Colors.green),
  arrivedAtFacility('At Facility', 'Items arrived at cleaning facility', Icons.business, Colors.brown),
  sorting('Sorting', 'Sorting items for processing', Icons.sort, Colors.amber),
  washing('Washing', 'Items being washed', Icons.water_drop, Colors.cyan),
  cleaning('Cleaning', 'Items being cleaned', Icons.cleaning_services, Colors.lightBlue),
  drying('Drying', 'Items being dried', Icons.air, Colors.blueGrey),
  ironing('Ironing', 'Items being ironed', Icons.heat_pump, Colors.deepOrange),
  readyForDelivery('Ready for Delivery', 'Items ready for delivery', Icons.check_circle_outline, Colors.lightGreen),
  outForDelivery('Out for Delivery', 'Items out for delivery', Icons.delivery_dining, Colors.deepPurple),
  reachedDeliveryLocation('Reached Delivery', 'Driver arrived at delivery location', Icons.flag, Colors.pink),
  delivered('Delivered', 'Order delivered successfully', Icons.done_all, Colors.green),
  completed('Completed', 'Order completed successfully', Icons.star, Colors.amber),
  cancelled('Cancelled', 'Order was cancelled', Icons.cancel, Colors.red),
  viewDetails('View Details', 'View order details', Icons.visibility, Colors.grey);

  const OrderStatus(this.displayName, this.description, this.icon, this.color);

  final String displayName;
  final String description;
  final IconData icon;
  final Color color;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get allowsCustomerActions {
    return this == OrderStatus.pending ||
           this == OrderStatus.confirmed ||
           this == OrderStatus.driverAssigned;
  }

  bool get isActive {
    return this != OrderStatus.cancelled &&
           this != OrderStatus.completed &&
           this != OrderStatus.delivered;
  }

  bool get canTrack {
    return [
      OrderStatus.outForPickup,
      OrderStatus.reachedPickupLocation,
      OrderStatus.pickedUp,
      OrderStatus.arrivedAtFacility,
      OrderStatus.washing,
      OrderStatus.cleaning,
      OrderStatus.drying,
      OrderStatus.ironing,
      OrderStatus.readyForDelivery,
      OrderStatus.outForDelivery,
      OrderStatus.reachedDeliveryLocation,
    ].contains(this);
  }

  bool get needsAttention {
    return this == OrderStatus.pending ||
           this == OrderStatus.outForPickup ||
           this == OrderStatus.outForDelivery;
  }

  bool get isUrgent {
    return this == OrderStatus.pending && DateTime.now().difference(DateTime.now()).inHours > 2;
  }

  bool get isOverdue {
    return this == OrderStatus.outForPickup ||
           this == OrderStatus.outForDelivery;
  }

  String get statusDescription {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for operator confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed and being processed';
      case OrderStatus.driverAssigned:
        return 'Driver assigned and on the way';
      case OrderStatus.outForPickup:
        return 'Driver collecting your items';
      case OrderStatus.reachedPickupLocation:
        return 'Driver has arrived at pickup location';
      case OrderStatus.pickedUp:
        return 'Items collected and in transit';
      case OrderStatus.arrivedAtFacility:
        return 'Items arrived at cleaning facility';
      case OrderStatus.sorting:
        return 'Sorting items for processing';
      case OrderStatus.washing:
        return 'Items are being washed';
      case OrderStatus.cleaning:
        return 'Items are being cleaned';
      case OrderStatus.drying:
        return 'Items are being dried';
      case OrderStatus.ironing:
        return 'Items are being ironed';
      case OrderStatus.readyForDelivery:
        return 'Items ready for delivery';
      case OrderStatus.outForDelivery:
        return 'Items out for delivery';
      case OrderStatus.reachedDeliveryLocation:
        return 'Driver has arrived at delivery location';
      case OrderStatus.delivered:
        return 'Order delivered successfully';
      case OrderStatus.completed:
        return 'Order completed successfully';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
      case OrderStatus.viewDetails:
        return 'View order details';
    }
  }

  List<OrderStatus> get availableActions {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.driverAssigned, OrderStatus.cancelled];
      case OrderStatus.driverAssigned:
        return [OrderStatus.outForPickup, OrderStatus.cancelled];
      case OrderStatus.outForPickup:
        return [OrderStatus.reachedPickupLocation, OrderStatus.cancelled];
      case OrderStatus.reachedPickupLocation:
        return [OrderStatus.pickedUp];
      case OrderStatus.pickedUp:
        return [OrderStatus.arrivedAtFacility];
      case OrderStatus.arrivedAtFacility:
        return [OrderStatus.sorting];
      case OrderStatus.sorting:
        return [OrderStatus.washing];
      case OrderStatus.washing:
        return [OrderStatus.cleaning];
      case OrderStatus.cleaning:
        return [OrderStatus.drying];
      case OrderStatus.drying:
        return [OrderStatus.ironing];
      case OrderStatus.ironing:
        return [OrderStatus.readyForDelivery];
      case OrderStatus.readyForDelivery:
        return [OrderStatus.outForDelivery];
      case OrderStatus.outForDelivery:
        return [OrderStatus.reachedDeliveryLocation];
      case OrderStatus.reachedDeliveryLocation:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
        return [OrderStatus.completed];
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.viewDetails:
        return [];
    }
  }

  double get progress {
    switch (this) {
      case OrderStatus.pending:
        return 0.1;
      case OrderStatus.confirmed:
        return 0.2;
      case OrderStatus.driverAssigned:
        return 0.3;
      case OrderStatus.outForPickup:
        return 0.4;
      case OrderStatus.reachedPickupLocation:
        return 0.45;
      case OrderStatus.pickedUp:
        return 0.5;
      case OrderStatus.arrivedAtFacility:
        return 0.55;
      case OrderStatus.sorting:
        return 0.6;
      case OrderStatus.washing:
        return 0.65;
      case OrderStatus.cleaning:
        return 0.7;
      case OrderStatus.drying:
        return 0.75;
      case OrderStatus.ironing:
        return 0.8;
      case OrderStatus.readyForDelivery:
        return 0.85;
      case OrderStatus.outForDelivery:
        return 0.9;
      case OrderStatus.reachedDeliveryLocation:
        return 0.95;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
      case OrderStatus.viewDetails:
        return 0.0;
    }
  }

  String get estimatedTime {
    switch (this) {
      case OrderStatus.pending:
        return '2-3 hours';
      case OrderStatus.confirmed:
        return '2-3 hours';
      case OrderStatus.driverAssigned:
        return '1-2 hours';
      case OrderStatus.outForPickup:
        return '30-45 min';
      case OrderStatus.reachedPickupLocation:
        return '15-20 min';
      case OrderStatus.pickedUp:
        return '1-2 hours';
      case OrderStatus.arrivedAtFacility:
        return '3-4 hours';
      case OrderStatus.sorting:
        return '30 min';
      case OrderStatus.washing:
        return '1 hour';
      case OrderStatus.cleaning:
        return '45 min';
      case OrderStatus.drying:
        return '30 min';
      case OrderStatus.ironing:
        return '45 min';
      case OrderStatus.readyForDelivery:
        return '15-30 min';
      case OrderStatus.outForDelivery:
        return '30-45 min';
      case OrderStatus.reachedDeliveryLocation:
        return '10-15 min';
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.viewDetails:
        return 'View details';
    }
  }

  String get estimatedTimeRemaining {
    return estimatedTime;
  }

  List<OrderStatus> get nextPossibleStatuses {
    return availableActions;
  }
}