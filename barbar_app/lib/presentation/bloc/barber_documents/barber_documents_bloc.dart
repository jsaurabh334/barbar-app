import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/barber_repository.dart';
import 'barber_documents_event.dart';
import 'barber_documents_state.dart';

class BarberDocumentsBloc extends Bloc<BarberDocumentsEvent, BarberDocumentsState> {
  final BarberRepository _barberRepository;

  BarberDocumentsBloc(this._barberRepository) : super(BarberDocumentsInitial()) {
    on<FetchDocuments>(_onFetchDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<ReplaceDocument>(_onReplaceDocument);
  }

  Future<void> _onFetchDocuments(FetchDocuments event, Emitter<BarberDocumentsState> emit) async {
    emit(BarberDocumentsLoading());
    try {
      final docs = await _barberRepository.listDocuments();
      emit(BarberDocumentsLoaded(docs));
    } catch (e) {
      emit(BarberDocumentsFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUploadDocument(UploadDocument event, Emitter<BarberDocumentsState> emit) async {
    emit(BarberDocumentsLoading());
    try {
      await _barberRepository.uploadDocument(event.docType, event.docUrl);
      final docs = await _barberRepository.listDocuments();
      emit(BarberDocumentsLoaded(docs));
    } catch (e) {
      emit(BarberDocumentsFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReplaceDocument(ReplaceDocument event, Emitter<BarberDocumentsState> emit) async {
    emit(BarberDocumentsLoading());
    try {
      await _barberRepository.replaceDocument(event.docId, event.docType, event.docUrl);
      final docs = await _barberRepository.listDocuments();
      emit(BarberDocumentsLoaded(docs));
    } catch (e) {
      emit(BarberDocumentsFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
