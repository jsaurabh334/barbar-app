import 'package:equatable/equatable.dart';

abstract class BarberEarningsEvent extends Equatable {
  const BarberEarningsEvent();

  @override
  List<Object?> get props => [];
}

class FetchEarnings extends BarberEarningsEvent {
  final String period;

  const FetchEarnings({this.period = 'week'});

  @override
  List<Object?> get props => [period];
}
