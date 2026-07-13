import 'package:equatable/equatable.dart';

abstract class BarberDocumentsEvent extends Equatable {
  const BarberDocumentsEvent();

  @override
  List<Object?> get props => [];
}

class FetchDocuments extends BarberDocumentsEvent {}

class UploadDocument extends BarberDocumentsEvent {
  final String docType;
  final String docUrl;

  const UploadDocument({required this.docType, required this.docUrl});

  @override
  List<Object?> get props => [docType, docUrl];
}

class ReplaceDocument extends BarberDocumentsEvent {
  final String docId;
  final String docType;
  final String docUrl;

  const ReplaceDocument({required this.docId, required this.docType, required this.docUrl});

  @override
  List<Object?> get props => [docId, docType, docUrl];
}
