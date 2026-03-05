class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['base_price'] ?? 0;

    return Service(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['service_name'] ?? 'Service').toString(),
      description: (json['description'] ?? '').toString(),
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString()) ?? 0,
      category: (json['category'] ?? 'General').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
    };
  }
}
