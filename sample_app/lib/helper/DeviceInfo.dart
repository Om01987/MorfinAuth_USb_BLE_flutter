class DeviceInfo {
  String SerialNo;
  String Make;
  String Model;
  int Width;
  int Height;
  int DPI = -1;

  DeviceInfo(this.SerialNo, this.Make, this.Model, this.Width, this.Height, this.DPI);

  factory DeviceInfo.fromJson(dynamic json) {
    return DeviceInfo(
        json['SerialNo'] as String,
        json['Make'] as String,
        json['Model'] as String,
        json['Width'] as int,
        json['Height'] as int,
        json['DPI'] as int);
  }

  @override
  Map<String, dynamic> toJson() => {
        "SerialNo": SerialNo,
        "Make": Make,
        "Model": Model,
        "Width": Width,
        "Height": Height,
        "DPI": DPI,
      };
}

