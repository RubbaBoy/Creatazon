import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  JsonEncoder encoder = JsonEncoder.withIndent('  ');

  Map<String, dynamic> json = {};
  args.skip(1).forEach((email) {
    json[email] = {
      "password": args[0],
      "name": "Haywood Jahblomy",
      "created": false
    };
  });

  File('accounts.json').writeAsStringSync(encoder.convert(json));
}
