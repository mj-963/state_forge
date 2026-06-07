import 'package:state_forge/state_forge.dart';

class Product {
  const Product(this.id, this.name, this.price);
  final String id, name;
  final double price;
}

// Zero boilerplate! No CatalogState class needed.
class CatalogStore extends Store<AsyncState<List<Product>>> {
  CatalogStore() : super(const Idle());

  Future<void> load() async {
    // If we have data, we could keep it while loading, 
    // but for this example we'll just show Loading.
    emit(const Loading());
    
    await Future.delayed(const Duration(seconds: 1));
    
    emit(const Success([
      Product('1', 'StateForge T-Shirt', 29.99),
      Product('2', 'Zero Codegen Mug', 14.99),
      Product('3', 'OOP Hoodie', 49.99),
    ]));
  }
}
