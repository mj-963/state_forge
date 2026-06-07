import 'package:flutter/material.dart';
import 'package:state_forge/state_forge.dart';
import 'core/api_client.dart';
import 'features/auth/auth_store.dart';
import 'features/cart/cart_store.dart';
import 'features/discovery/discovery_page.dart';
import 'features/discovery/discovery_store.dart';

/// ForgeMovies: A real-world stress test application for StateForge.
/// 
/// This app demonstrates:
/// 1. Global Stores (Auth, Cart) provided at the root.
/// 2. Feature-specific, paginated stores (Discovery).
/// 3. AsyncState pattern matching for clean UI.
/// 4. Global Error Handling and Debug Mode.
void main() {
  // 1. Initialize the StateForge system
  StateForge.init();
  
  // 2. Enable console logging of state transitions
  StateForge.debugMode = true;

  // 3. Setup global hooks for crash reporting
  StateForge.onError = (error, stack) {
    debugPrint('Global Error Caught: $error');
  };

  final apiClient = ApiClient();

  runApp(
    // 4. Use ForgeMultiProvider to flatten the global store tree
    ForgeMultiProvider(
      providers: [
        StoreProvider<AuthStore>(create: (_) => AuthStore()),
        StoreProvider<CartStore>(create: (_) => CartStore()),
        // We load the initial discovery data immediately
        StoreProvider<DiscoveryStore>(create: (_) => DiscoveryStore(apiClient)..load()),
      ],
      child: const MovieApp(),
    ),
  );
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ForgeMovies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

/// The entry point for the app. Demonstrates how to handle side effects
/// like navigation using the [ForgeEffectListener] mixin.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with ForgeEffectListener {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to the 'login_success' string effect to trigger navigation
    listenToEffect<AuthStore, String>((effect) {
      if (effect == 'login_success') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DiscoveryPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ForgeBuilder<AuthStore, AsyncState<String>>(
        builder: (context, state, store) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_filter, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('ForgeMovies', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  
                  // Use functional pattern matching for the login state
                  state.maybeWhen(
                    failure: (e) => Text(e.toString(), style: const TextStyle(color: Colors.red)),
                    orElse: () => const Text('Please login to continue'),
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => store.login('mj@stateforge.dev', 'password'),
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login with StateForge'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
