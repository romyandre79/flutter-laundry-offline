import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/settings_repository.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/settings/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository(),
        super(SettingsInitial());

  LaundryInfo? _currentInfo;
  LaundryInfo? get currentInfo => _currentInfo;

  Future<void> loadSettings() async {
    emit(SettingsLoading());

    try {
      final settings = await _repository.getAllSettings();

      final laundryInfo = LaundryInfo(
        name: settings[AppConstants.keyLaundryName] ??
            AppConstants.defaultLaundryName,
        address: settings[AppConstants.keyLaundryAddress] ??
            AppConstants.defaultLaundryAddress,
        phone: settings[AppConstants.keyLaundryPhone] ??
            AppConstants.defaultLaundryPhone,
        invoicePrefix: settings[AppConstants.keyInvoicePrefix] ??
            AppConstants.defaultInvoicePrefix,
        fonnteToken: settings[AppConstants.keyFonnteToken] ?? 
            AppConstants.defaultFonnteToken,
      );

      _currentInfo = laundryInfo;
      emit(SettingsLoaded(laundryInfo: laundryInfo));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memuat pengaturan: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryName(String name) async {
    if (name.trim().isEmpty) {
      emit(const SettingsError(message: 'Nama laundry tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyLaundryName, name.trim());

      final updatedInfo = _currentInfo!.copyWith(name: name.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nama laundry berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui nama: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryAddress(String address) async {
    if (address.trim().isEmpty) {
      emit(const SettingsError(message: 'Alamat tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyLaundryAddress, address.trim());

      final updatedInfo = _currentInfo!.copyWith(address: address.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Alamat berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui alamat: ${e.toString()}'));
    }
  }

  Future<void> updateLaundryPhone(String phone) async {
    if (phone.trim().isEmpty) {
      emit(const SettingsError(message: 'Nomor HP tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyLaundryPhone, phone.trim());

      final updatedInfo = _currentInfo!.copyWith(phone: phone.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nomor HP berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(
          SettingsError(message: 'Gagal memperbarui nomor HP: ${e.toString()}'));
    }
  }

  Future<void> updateInvoicePrefix(String prefix) async {
    if (prefix.trim().isEmpty) {
      emit(const SettingsError(message: 'Prefix invoice tidak boleh kosong'));
      return;
    }

    if (prefix.trim().length > 10) {
      emit(const SettingsError(message: 'Prefix invoice maksimal 10 karakter'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyInvoicePrefix, prefix.trim().toUpperCase());

      final updatedInfo =
          _currentInfo!.copyWith(invoicePrefix: prefix.trim().toUpperCase());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Prefix invoice berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(
          message: 'Gagal memperbarui prefix invoice: ${e.toString()}'));
    }
  }

  Future<void> updateFonnteToken(String token) async {
    if (token.trim().isEmpty) {
      emit(const SettingsError(message: 'Token Fonnte tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyFonnteToken, token.trim());

      final updatedInfo = _currentInfo!.copyWith(fonnteToken: token.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Token Fonnte berhasil diperbarui',
        laundryInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(
          message: 'Gagal memperbarui Token Fonnte: ${e.toString()}'));
    }
  }
}
