// home_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState(index: 0));

  // Function to change the selected tab index
  void changeTab(int index) {
    emit(HomeState(index: index));
  }
}
