import '../entities/device_info.dart';
import '../repositories/settings_repository.dart';

class GetDeviceIdUseCase {
  final SettingsRepository repository;

  GetDeviceIdUseCase(this.repository);

  Future<DeviceInfo> call() {
    return repository.getDeviceInfo();
  }
}
