import 'package:flutter_bloc/flutter_bloc.dart';

class MainState {
  final int currentIndex;

  MainState({this.currentIndex = 0});

  MainState copyWith({int? currentIndex}) {
    return MainState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(MainState());

  void changeTab(int index) {
    emit(state.copyWith(currentIndex: index));
  }
} 