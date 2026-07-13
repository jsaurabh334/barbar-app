import 'package:equatable/equatable.dart';

abstract class BarberEarningsState extends Equatable {
  const BarberEarningsState();

  @override
  List<Object?> get props => [];
}

class BarberEarningsInitial extends BarberEarningsState {}

class BarberEarningsLoading extends BarberEarningsState {}

class BarberEarningsLoaded extends BarberEarningsState {
  final String period;
  final double total;
  final List<Map<String, dynamic>> earnings;

  const BarberEarningsLoaded({
    required this.period,
    required this.total,
    required this.earnings,
  });

  @override
  List<Object?> get props => [period, total, earnings];
}

class BarberEarningsFailure extends BarberEarningsState {
  final String error;

  const BarberEarningsFailure(this.error);

  @override
  List<Object?> get props => [error];
}
