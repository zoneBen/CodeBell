import '../entities/device_info.dart';
import '../repositories/settings_repository.dart';

class SaveDeviceIdUseCase {
  final SettingsRepository repository;

  SaveDeviceIdUseCase(this.repository);

  Future<void> call(DeviceInfo info) {
    return repository.saveDeviceInfo(info);
  }
}
