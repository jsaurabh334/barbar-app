import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import 'barber_earnings_event.dart';
import 'barber_earnings_state.dart';

class BarberEarningsBloc extends Bloc<BarberEarningsEvent, BarberEarningsState> {
  final BarberRepository _barberRepository;

  BarberEarningsBloc(this._barberRepository) : super(BarberEarningsInitial()) {
    on<FetchEarnings>(_onFetchEarnings);
  }

  Future<void> _onFetchEarnings(FetchEarnings event, Emitter<BarberEarningsState> emit) async {
    emit(BarberEarningsLoading());
    try {
      final data = await _barberRepository.getEarnings(period: event.period);
      emit(BarberEarningsLoaded(
        period: event.period,
        total: (data['total'] as num?)?.toDouble() ?? 0.0,
        earnings: (data['earnings'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      ));
    } catch (e) {
      emit(BarberEarningsFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
