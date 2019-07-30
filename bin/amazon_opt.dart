import 'dart:async';
import 'dart:io';

import 'package:webdriver/io.dart';

class AmazonOTP {
  WebDriver _driver;
  WebElement _prevFirst;
  RegExp _otpRegex = RegExp(r'\(OTP\): (\d{6})');

  bool changed = false;
  String currentOTP = '';

  Future start(List<String> args) async {
    _driver = await createDriver(
        uri: Uri.parse('http://localhost:4444/'), spec: WebDriverSpec.JsonWire);
    await _driver.get('https://gmail.com/');

    print('Inputting credentials...');

    var email = await getElement(By.cssSelector('input[type=email]'));
    await email.sendKeys(args[0]);

    var next = await getElement(By.id('ipdentifierNext'));
    await next.click();

    sleep(Duration(seconds: 1));

    var password = await getElement(By.cssSelector('input[type=password]'));
    await password.sendKeys(args[1]);

    var lastNext = await getElement(By.id('passwordNext'));
    await lastNext.click();

    await getElement(By.cssSelector('span > a[title=Inbox]'), duration: 10000);

    print('Authenticated and loaded into gmail!');

    await _driver.findElement(By.cssSelector(
        'div[jsaction] > div > div > div > div > table > tbody'));
    await checkMessage();
  }

  Future<void> checkMessage() async {
    var first = await getElement(By.cssSelector(
        'div[jsaction] > div > div > div > div > table > tbody div[role=link] > div > span'));
    if (_prevFirst == null) _prevFirst = first;
    if (_prevFirst != first) {
      _prevFirst = first;
      String text = await first.text;
      print('New message:');
      print('   $text');
      var otp = _otpRegex.firstMatch(text)?.group(1) ?? 'idk';
      print('New is: $otp');
      changed = true;
      currentOTP = otp;
    }

    Timer(Duration(seconds: 1), () => checkMessage());
  }

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
