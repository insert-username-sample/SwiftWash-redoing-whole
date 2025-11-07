import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/pricing_data.dart';
import 'package:swiftwash_mobile/cart_service.dart';

class Step1Widget extends StatefulWidget {
  final PageController pageController;
  final Function(List<Map<String, dynamic>>, String) onUpdate;
  final String selectedService;
  final List<Map<String, dynamic>> initialItems;

  const Step1Widget({super.key, required this.pageController, required this.onUpdate, required this.selectedService, this.initialItems = const []});

  @override
  _Step1WidgetState createState() => _Step1WidgetState();
}

class _Step1WidgetState extends State<Step1Widget> {
  late List<Map<String, dynamic>> _items;

  final Map<String, IconData> _iconMap = {
    'T-Shirt': Icons.person,
    'Shirt (Formal)': Icons.person_outline,
    'Jeans': Icons.person,
    'Trousers': Icons.person_outline,
    'Shorts': Icons.person,
    'Saree': Icons.person,
    'Dhoti / Lungi': Icons.person,
    'Kurta / Kurti': Icons.person,
    'Blouse': Icons.person,
    'Skirt': Icons.person,
    'Salwar / Leggings': Icons.person,
    'Dupatta / Stole': Icons.person,
    'Undergarments (pair)': Icons.person_outline,
    'Socks (pair)': Icons.person_outline,
    'Towel': Icons.single_bed,
    'Bedsheet (Single)': Icons.single_bed,
    'Bedsheet (Double)': Icons.single_bed,
    'Pillow Covers (pair)': Icons.single_bed,
    'Curtains (panel)': Icons.single_bed,
    'Napkin / Table Linen': Icons.single_bed,
    'Jeans (heavy wash)': Icons.person,
    'Dhoti': Icons.person,
    'Kurta': Icons.person,
    'Kurti': Icons.person,
    'Dupatta': Icons.person,
  };

  @override
  void initState() {
    super.initState();
    _items = _getInitialItems();

    if (widget.initialItems.isNotEmpty) {
      final Map<String, int> initialQuantities = {
        for (var item in widget.initialItems) item['name']: item['quantity']
      };
      for (var item in _items) {
        if (initialQuantities.containsKey(item['name'])) {
          item['quantity'] = initialQuantities[item['name']]!;
        }
      }
    }
  }

  List<Map<String, dynamic>> _getInitialItems() {
    Map<String, double> prices;
    switch (widget.selectedService) {
      case 'Ironing':
        prices = PricingData.ironingPrices;
        break;
      case 'Swift':
        prices = PricingData.swiftPrices;
        break;
      default:
        prices = PricingData.laundryPrices;
    }

    return prices.entries.map((entry) {
      final icon = _iconMap[entry.key] ?? Icons.person;
      return {
        'name': entry.key,
        'price': entry.value,
        'quantity': 0,
        'icon': icon,
        'serviceName': widget.selectedService,
      };
    }).toList();
  }

  int get _totalItems => _items.fold(0, (sum, item) => sum + (item['quantity'] as int));
  double get _totalCost => _items.fold(0, (sum, item) => sum + (item['quantity'] as int) * (item['price'] as double));

  void _updateQuantity(int index, int change) {
    setState(() {
      final newQuantity = _items[index]['quantity'] + change;
      if (newQuantity >= 0) {
        _items[index]['quantity'] = newQuantity;
        widget.onUpdate(_items, widget.selectedService);
        CartService.saveCart(_items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Items', style: AppTypography.h1),
                const SizedBox(height: 4),
                Text('Choose what you\'d like us to clean today.', style: AppTypography.subtitle),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final icon = _items[index]['icon'] as IconData;
                return _ItemCard(
                  icon: icon,
                  name: _items[index]['name'],
                  price: _items[index]['price'],
                  quantity: _items[index]['quantity'],
                  onAdd: () => _updateQuantity(index, 1),
                  onRemove: () => _updateQuantity(index, -1),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: _totalItems > 0 ? AppColors.bookingCardGradient : null,
              color: _totalItems > 0 ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _totalItems > 0
                  ? () {
                      widget.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Container(
                alignment: Alignment.center,
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select items to continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_totalCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ItemCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final double price;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.icon,
    required this.name,
    required this.price,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandBlue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.cardTitle),
                  Text('₹${price.toStringAsFixed(0)}/piece', style: AppTypography.cardSubtitle.copyWith(color: const Color(0xFF4aae5a))),
                ],
              ),
            ),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed: onRemove,
                  isGradient: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isGradient;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.isGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: isGradient ? AppColors.bookingButtonGradient : null,
            color: isGradient ? null : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 16, color: isGradient ? Colors.white : Colors.grey.shade700),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
