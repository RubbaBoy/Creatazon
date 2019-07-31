import 'dart:convert';

import 'dart:io';

// host port username password database
void main(List<String> args) {
  print('Converting from Creatazon file to Scamazon config file...');
  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  Map<String, dynamic> accounts = jsonDecode(File('accounts.json').readAsStringSync());

  Map<String, dynamic> writing = {};

  Map<String, dynamic> database = {};
  database['host'] = args[0];
  database['port'] = int.parse(args[1]);
  database['username'] = args[2];
  database['password'] = args[3];
  database['database'] = args[4];
  writing['database'] = database;

  var writingAccounts = [];

  accounts.forEach((email, data) {
    if (!data['created']) return;
    writingAccounts.add({
      'username': email,
      'password': data['password'],
      'cookies': data.containsKey('cookies') ? data['cookies'] : null
    });
  });
  writing['accounts'] = writingAccounts;

  File('config.json').writeAsStringSync(encoder.convert(writing));
}