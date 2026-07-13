abstract class BarberStaffEvent {}

class FetchStaff extends BarberStaffEvent {}

class AddStaff extends BarberStaffEvent {
  final Map<String, dynamic> staffData;
  AddStaff(this.staffData);
}

class UpdateStaff extends BarberStaffEvent {
  final String staffId;
  final Map<String, dynamic> updates;
  UpdateStaff(this.staffId, this.updates);
}

class ArchiveStaff extends BarberStaffEvent {
  final String staffId;
  ArchiveStaff(this.staffId);
}
