import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  JsonEncoder encoder = JsonEncoder.withIndent('  ');

  Map<String, dynamic> json = {};
  args.forEach((email) {
    json[email] = {
      "password": "shitshit",
      "created": false
    };
  });

  File('accounts.json').writeAsStringSync(encoder.convert(json));
}