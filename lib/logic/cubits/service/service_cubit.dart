import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/service_repository.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_state.dart';

class ServiceCubit extends Cubit<ServiceState> {
  final ServiceRepository _serviceRepository;
  List<Service> _services = [];

  ServiceCubit({ServiceRepository? serviceRepository})
      : _serviceRepository = serviceRepository ?? ServiceRepository(),
        super(const ServiceInitial());

  List<Service> get services => _services;

  /// Load all active services
  Future<void> loadServices() async {
    emit(const ServiceLoading());

    try {
      _services = await _serviceRepository.getAllServices();
      emit(ServiceLoaded(_services));
    } catch (e) {
      emit(ServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Add new service
  Future<void> addService(Service service) async {
    emit(const ServiceLoading());

    try {
      // Check duplicate name
      final exists = await _serviceRepository.serviceNameExists(service.name);
      if (exists) {
        emit(const ServiceError('Nama layanan sudah ada'));
        emit(ServiceLoaded(_services));
        return;
      }

      await _serviceRepository.createService(service);
      emit(const ServiceOperationSuccess('Layanan berhasil ditambahkan'));

      // Reload services
      await loadServices();
    } catch (e) {
      emit(ServiceError(e.toString().replaceAll('Exception: ', '')));
      emit(ServiceLoaded(_services));
    }
  }

  /// Update existing service
  Future<void> updateService(Service service) async {
    emit(const ServiceLoading());

    try {
      // Check duplicate name (excluding current service)
      final exists = await _serviceRepository.serviceNameExists(
        service.name,
        excludeId: service.id,
      );
      if (exists) {
        emit(const ServiceError('Nama layanan sudah ada'));
        emit(ServiceLoaded(_services));
        return;
      }

      await _serviceRepository.updateService(service);
      emit(const ServiceOperationSuccess('Layanan berhasil diupdate'));

      // Reload services
      await loadServices();
    } catch (e) {
      emit(ServiceError(e.toString().replaceAll('Exception: ', '')));
      emit(ServiceLoaded(_services));
    }
  }

  /// Delete service (soft delete)
  Future<void> deleteService(int id) async {
    emit(const ServiceLoading());

    try {
      await _serviceRepository.deleteService(id);
      emit(const ServiceOperationSuccess('Layanan berhasil dihapus'));

      // Reload services
      await loadServices();
    } catch (e) {
      emit(ServiceError(e.toString().replaceAll('Exception: ', '')));
      emit(ServiceLoaded(_services));
    }
  }
}
