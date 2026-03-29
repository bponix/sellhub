import 'package:equatable/equatable.dart';

class StoreShellState extends Equatable {
  const StoreShellState({this.currentIndex = 0});

  final int currentIndex;

  StoreShellState copyWith({int? currentIndex}) {
    return StoreShellState(currentIndex: currentIndex ?? this.currentIndex);
  }

  @override
  List<Object?> get props => [currentIndex];
}
