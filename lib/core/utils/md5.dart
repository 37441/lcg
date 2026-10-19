import 'dart:convert';

import 'package:crypto/crypto.dart';

/// MD5（小写 hex）—— Discuz 登录协议：password = md5(md5(明文) + saltkey)
String md5Hex(String input) => md5.convert(utf8.encode(input)).toString();
