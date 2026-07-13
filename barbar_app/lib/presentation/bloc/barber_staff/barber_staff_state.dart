import '../../../data/models/staff_model.dart';

abstract class BarberStaffState {}

class BarberStaffInitial extends BarberStaffState {}

class BarberStaffLoading extends BarberStaffState {}

class BarberStaffLoaded extends BarberStaffState {
  final List<StaffModel> staffMembers;
  BarberStaffLoaded(this.staffMembers);
}

class BarberStaffOperationSuccess extends BarberStaffState {
  final String message;
  BarberStaffOperationSuccess(this.message);
}

class BarberStaffError extends BarberStaffState {
  final String message;
  BarberStaffError(this.message);
}
