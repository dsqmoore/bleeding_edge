// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();
  List events = [];

  bool shouldForward = true;
  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked = Zone.current.fork(specification: new ZoneSpecification(
      run: (Zone self, ZoneDelegate parent, Zone origin, f()) {
        // The zone is still the same as when origin.run was invoked, which
        // is the root zone. (The origin zone hasn't been set yet).
        Expect.identical(Zone.current, Zone.ROOT);
        events.add("forked.run");
        if (shouldForward) return parent.run(origin, f);
        return 42;
      }));

  events.add("zone forked");
  Zone expectedZone = forked;
  var result = forked.run(() {
    Expect.identical(expectedZone, Zone.current);
    events.add("run closure");
    return 499;
  });
  Expect.equals(499, result);
  events.add("executed run");

  shouldForward = false;
  result = forked.run(() {
    Expect.fail("should not be invoked");
  });
  Expect.equals(42, result);
  events.add("executed run2");

  asyncStart();
  shouldForward = true;
  result = forked.run(() {
    Expect.identical(forked, Zone.current);
    events.add("run closure 2");
    runAsync(() {
      events.add("run closure 3");
      Expect.identical(forked, Zone.current);
      done.complete(true);
    });
    return 1234;
  });
  events.add("after nested runAsync");
  Expect.equals(1234, result);

  done.future.whenComplete(() {
    Expect.listEquals(
        ["zone forked", "forked.run", "run closure", "executed run",
        "forked.run", "executed run2", "forked.run", "run closure 2",
        "after nested runAsync", "forked.run", "run closure 3"],
        events);
    asyncEnd();
  });
}