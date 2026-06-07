import 'package:state_forge/state_forge.dart';

// No more custom sealed classes for standard async states!
// We use built-in AsyncState<String> where String is the user name.

class AuthStore extends Store<AsyncState<String>> {
  AuthStore() : super(const Idle());

  Future<void> login(String email, String password) async {
    emit(const Loading());
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'mj@stateforge.dev' && password == 'password') {
      emit(const Success('MJ'));
      // Simple string effect - no sealed class needed for basic events!
      effect('login_success');
    } else {
      emit(const Failure('Invalid credentials'));
    }
  }

  void logout() {
    emit(const Idle());
  }
}
