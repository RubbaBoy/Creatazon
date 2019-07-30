import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:webdriver/io.dart';
import 'amazon_opt.dart';
import 'utils.dart';

Future<void> main(List<String> args) async => await Creatazon().main(args);

class Creatazon {
  Utils _;
  WebDriver _driver;
  Map<String, dynamic> accounts = {};
  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  var amazonOtp = AmazonOTP();

  double start = -1;
  int initialAccounts = 0;
  int accountsCreated = 0;

  Future main(List<String> args) async {
    _driver = await createDriver(uri: Uri.parse('http://localhost:4444/'), spec: WebDriverSpec.JsonWire);
    _ = Utils(_driver);
    print('Starting amazon OTP fetcher...');

    await amazonOtp.start(this, args);

    print('Loading accounts to create...');
    loadAccounts();
    var emails = accounts.keys.toList();
    var index = 0;

    void createShit() {
      var email = emails[index++];
      print('Creating shit: $email');
      var data = accounts[email];
      if (data['created']) {
        createShit();
        return;
      }

      var pass = data['password'];
      var name = data['name'];
      if (start == -1) start = DateTime.now().millisecondsSinceEpoch.toDouble();
      createAccount(email, pass, name).then((_) => createShit());
    }

    initialAccounts = accounts.keys.where((email) => accounts[email]['created']).length;
    createShit();
  }

  Future<void> createAccount(String email, String password, String name) async {
    await _driver.get('https://www.amazon.com/ap/register?showRememberMe=true&openid.pape.max_auth_age=0&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&pageId=usflex&openid.return_to=https%3A%2F%2Fwww.amazon.com%2Fgp%2Fyourstore%2Fhome%3Fie%3DUTF8%26action%3Dsign-out%26path%3D%252Fgp%252Fyourstore%252Fhome%26ref_%3Dnav_youraccount_signout%26signIn%3D1%26useRedirectOnSuccess%3D1&prevRID=6VXB3JMD8Z7FBYF51Z0E&openid.assoc_handle=usflex&openid.mode=checkid_setup&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&prepopulatedLoginId=&failedSignInCount=0&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&ubid=131-9962970-1381959');
    await (await _.getElement(By.id('ap_customer_name'))).sendKeys(name);
    await (await _.getElement(By.id('ap_email'))).sendKeys(email);
    await (await _.getElement(By.id('ap_password'))).sendKeys(email);
    await (await _.getElement(By.id('ap_password_check'))).sendKeys(email);
    await (await _.getElement(By.id('continue'))).click();

    sleep(Duration(milliseconds: 250));
    var alertContents = (await (await _driver.findElement(By.cssSelector('#authportal-main-section'))).text).toLowerCase();

    bool alreadyInUse = alertContents.contains('exists');
    bool captcha = alertContents.contains('enter the characters');

    if (alreadyInUse) {
      print('Email is already in use: $email');
      accounts[email]['created'] = true;
      saveAccounts();
      sleep(Duration(milliseconds: 500));
      return;
    }

    Future<void> processCaptcha() async {
      print('==============================');
      print('Type captcha below:');

      await (await _.getElement(By.id('ap_password'))).sendKeys(email);
      await (await _.getElement(By.id('ap_password_check'))).sendKeys(email);

      var line = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
      await (await _.getElement(By.id('auth-captcha-guess'))).sendKeys(line.trim());
      await (await _.getElement(By.id('continue'))).click();

      sleep(Duration(milliseconds: 250));

      var mainSections = await (await _driver.findElements(By.cssSelector('#authportal-main-section'))).toList();

      if (mainSections.isNotEmpty) {
        var alertContents = (await mainSections[0].text).toLowerCase();
        if (alertContents.contains('enter the characters')) {
          print('Fucking dumbass, you got it wrong.');
          await processCaptcha();
          return;
        }
      }
    }

    if (captcha) await processCaptcha();

    var verifyTitle = await _.getElement(By.cssSelector('form > div > div > h1'));
    String text = await verifyTitle?.text;
    print(text);

    if (text != 'Verify email address') {
      print('There was no "Verify email address" form for $email');
      return;
    }

    print('Continuing with OTP fetching...');

    var otp = await amazonOtp.getOTP();

    print('Found OTP: $otp');

    if (otp == null) {
      print('OTP is null! Continuing...');
      return;
    }

    var otpEnter = await _.getElement(By.className('cvf-widget-input-code'));
    await otpEnter.sendKeys(otp);

    var verifyButton = await _.getElement(By.cssSelector('.a-button-inner .a-button-input'));
    await verifyButton.click();

    accounts[email]['created'] = true;
    accountsCreated++;
    saveAccounts();
    printStatus();

    sleep(Duration(milliseconds: 250));
  }

  void printStatus() {
    print('==== $accountsCreated created this session, ${accountsCreated + initialAccounts} total @ ${((DateTime.now().millisecondsSinceEpoch - start) / 1000) / accountsCreated} seconds/account ====');
  }

  void loadAccounts() =>
      accounts = jsonDecode(File('accounts.json').readAsStringSync());

  void saveAccounts() =>
      File('accounts.json').writeAsStringSync(encoder.convert(accounts));
}
