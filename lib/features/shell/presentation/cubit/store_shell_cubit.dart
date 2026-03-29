import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_state.dart';

class StoreShellCubit extends SafeCubit<StoreShellState> {
  StoreShellCubit() : super(const StoreShellState());

  void setIndex(int index) {
    if (index == state.currentIndex) return;
    emit(state.copyWith(currentIndex: index));
  }
}
