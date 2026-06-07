import 'package:state_forge/state_forge.dart';

class ProfileState {
  const ProfileState({this.name = '', this.email = '', this.isEditing = false});

  final String name;
  final String email;
  final bool isEditing;

  // Pattern B: Named transitions
  ProfileState toggleEdit() =>
      ProfileState(name: name, email: email, isEditing: !isEditing);
  ProfileState updateName(String newName) =>
      ProfileState(name: newName, email: email, isEditing: isEditing);
  ProfileState updateEmail(String newEmail) =>
      ProfileState(name: name, email: newEmail, isEditing: isEditing);
  ProfileState copyWith({String? name, String? email, bool? isEditing}) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ProfileStore extends Store<ProfileState> {
  ProfileStore()
    : super(const ProfileState(name: 'MJ', email: 'mj@stateforge.dev'));

  void toggleEdit() => emit(state.toggleEdit());
  void updateName(String name) => emit(state.updateName(name));
  void updateEmail(String email) => emit(state.updateEmail(email));

  void save() {
    emit(state.toggleEdit());
    effect('Profile saved!');
  }
}
