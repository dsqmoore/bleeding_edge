// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_class_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class CodeATest extends VmServiceRequestHelper {
  CodeATest(port, id, codeId) :
      super('http://127.0.0.1:$port/isolates/$id/objects/$codeId');

  onRequestCompleted(Map reply) {
    Expect.equals('Code', reply['type']);
    Expect.equals('a', reply['function']['name']);
    Expect.isTrue(reply['disassembly'].length > 0);
  }
}

class CodeCTest extends VmServiceRequestHelper {
  CodeCTest(port, id, codeId) :
      super('http://127.0.0.1:$port/isolates/$id/objects/$codeId');

  onRequestCompleted(Map reply) {
    Expect.equals('Code', reply['type']);
    Expect.equals('C.c', reply['function']['user_name']);
    Expect.isTrue(reply['disassembly'].length > 0);
  }
}

class StackTraceTest extends VmServiceRequestHelper {
  StackTraceTest(port, id) :
      super('http://127.0.0.1:$port/isolates/$id/stacktrace');

  int _aId;
  int _cId;
  onRequestCompleted(Map reply) {
    Expect.equals('StackTrace', reply['type']);
    List members = reply['members'];
    Expect.equals('a', members[0]['name']);
    _aId = members[0]['code']['id'];
    Expect.equals('c', members[2]['name']);
    _cId = members[2]['code']['id'];
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  int _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(2);
    tester.checkIsolateNameContains('isolate_stacktrace_command_script.dart');
    _isolateId = tester.checkIsolateNameContains('myIsolateName');
  }
}

main() {
  var process = new TestLauncher('isolate_stacktrace_command_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var stackTraceTest =
          new StackTraceTest(port, test._isolateId);
      stackTraceTest.makeRequest().then((_) {
        var codeATest = new CodeATest(port, test._isolateId,
                                      stackTraceTest._aId);
        var codeCTest = new CodeCTest(port, test._isolateId,
                                      stackTraceTest._cId);
        var requests = Future.wait([codeATest.makeRequest(),
                                    codeCTest.makeRequest()]);
        requests.then((_) {
          process.requestExit();
        });
      });
    });
  });
}
