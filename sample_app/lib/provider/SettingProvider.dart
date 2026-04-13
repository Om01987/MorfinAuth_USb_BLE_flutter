import 'package:flutter/cupertino.dart';

class SettingProvider extends ChangeNotifier {
  int timeOut = 10000;
  int quality = 60;
  int imageType = 0;
  int templateType = 0;

  void settimeOut(int timeOut) {
    this.timeOut = timeOut;
    notifyListeners();
  }

  void setQuality(int quality) {
    this.quality = quality;
    notifyListeners();
  }

  void setImageType(int imageType) {
    this.imageType = imageType;
    notifyListeners();
  }

  void setTemplateType(int templateType) {
    this.templateType = templateType;
    notifyListeners();
  }

  int getTimeOut() {
    return timeOut;
  }

  int getQuality() {
    return quality;
  }

  int getImageType() {
    return imageType;
  }

  int getTemplateType(){
    return templateType;
  }

}
