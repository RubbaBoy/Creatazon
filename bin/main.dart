import 'dart:convert';
import 'dart:io';

import 'amazon_opt.dart';

Map<String, dynamic> accounts = {};
JsonEncoder encoder = JsonEncoder.withIndent('  ');
var amazonOtp = AmazonOTP();

void main(List<String> args) {
  print('Starting amazon OTP fetcher...');

  amazonOtp.start(args);

  print('Loading accounts to create...');
  loadAccounts();

  accounts.forEach((email, data) {
    if (data['created']) return;
    var pass = data['password'];
  });

}

void loadAccounts() => accounts = jsonDecode(File('accounts.json').readAsStringSync());

void saveAccounts() => File('accounts.json').writeAsStringSync(encoder.convert(accounts));
