// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Negative test to make sure that we are reaching all assertions.
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=spawn_uri_child_isolate.dart
library spawn_tests;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

main() {
  test('isolate fromUri - negative test', () {
    ReceivePort port = new ReceivePort();
    port.first.then(expectAsync1((msg) {
      expect(msg, equals('re: hello')); // should be hi, not hello
    }));

    Isolate.spawnUri(Uri.parse('spawn_uri_child_isolate.dart'),
                     ['hi'], port.sendPort);
  });
}
