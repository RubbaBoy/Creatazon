import 'dart:io';

import 'package:webdriver/io.dart';

class Utils {

  WebDriver _driver;

  Utils(this._driver);

  Future<WebElement> getElement(By by,
      {int duration = 1000, int checkInterval = 100}) async {
    var element;
    do {
      try {
        element = await _driver.findElement(by);
        if (element != null) return element;
      } catch (ignored) {}
      sleep(Duration(milliseconds: checkInterval));
      duration -= checkInterval;
    } while (element == null && duration > 0);
    return element;
  }
}
