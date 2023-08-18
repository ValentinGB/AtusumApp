class Device {
  String id;
  bool active;
  String deviceId;
  String phoneNumber;
  String description;

  Device(
      {this.id,
      this.active,
      this.deviceId,
      this.phoneNumber,
      this.description});

  Device.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    active = json['active'];
    deviceId = json['deviceId'];
    phoneNumber = json['phoneNumber'];
    description = json['description'];
  }
}
