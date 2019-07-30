import 'dart:async';
import 'dart:io';

import 'package:webdriver/io.dart';

import 'main.dart';
import 'utils.dart';

class AmazonOTP {
  Utils _;
  WebDriver _driver;
  RegExp _otpRegex = RegExp(r'\(OTP\): (\d{6})');

  Future<void> start(Creatazon creatazon, List<String> args) async {
    _driver = await createDriver(
        uri: Uri.parse('http://localhost:4444/'), spec: WebDriverSpec.JsonWire);
    _ = Utils(_driver);
    await _driver.get('https://gmail.com/');

    print('Inputting credentials...');

    var email = await _.getElement(By.cssSelector('input[type=email]'));
    await email.sendKeys(args[0]);

    var next = await _.getElement(By.id('identifierNext'));
    await next.click();

    sleep(Duration(seconds: 1));

    var password = await _.getElement(By.cssSelector('input[type=password]'));
    await password.sendKeys(args[1]);

    var lastNext = await _.getElement(By.id('passwordNext'));
    await lastNext.click();

    await _.getElement(By.cssSelector('span > a[title=Inbox]'),
        duration: 10000);

    print('Authenticated and loaded into gmail!');

    await _.getElement(By.cssSelector(
        'div[jsaction] > div > div > div > div > table > tbody'));
  }

  Future<String> getOTP() async {
    var first;
    do {
      var emails = await (await _driver.findElements(By.cssSelector(
          'div[jsaction] > div > div > div > div > table > tbody div[role=link] > div > span')))
          .toList();
      first = emails.isNotEmpty ? emails[0] : null;
      sleep(Duration(milliseconds: 100));
    } while (first == null);

    String text = await first.text;
    var otp = _otpRegex.firstMatch(text)?.group(1) ?? 'idk';
    await deleteAll();
    return otp;
  }

  Future<void> deleteAll() async {
    await (await _driver.findElement(By.cssSelector('div[data-tooltip=Select] > div > span[role=checkbox]'))).click();

    sleep(Duration(milliseconds: 250));

    await (await _driver.findElement(By.cssSelector('div[data-tooltip=Delete] > div'))).click();
  }
}
