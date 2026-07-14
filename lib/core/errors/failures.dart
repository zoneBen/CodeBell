abstract class Failure {
  final String message;

  const Failure(this.message);
}

class MqttFailure extends Failure {
  const MqttFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
