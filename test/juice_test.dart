import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/juice.dart';

void main() {
  test('Sparks fade out and the shake settles', () {
    final juice = Juice();
    juice.burst(const Offset(.5, .5), Colors.white, count: 10);
    juice.kick(1);
    expect(juice.sparks, hasLength(10));
    expect(juice.active, isTrue);
    for (var i = 0; i < 60; i++) {
      juice.step(1 / 60);
    }
    expect(juice.sparks, isEmpty);
    expect(juice.shake, 0);
    expect(juice.active, isFalse);
    expect(juice.offset, Offset.zero);
  });

  test('Nothing is added when effects are off (reduced motion)', () {
    final juice = Juice()..enabled = false;
    juice.burst(Offset.zero, Colors.white);
    juice.kick(1);
    expect(juice.active, isFalse);
  });

  test('The number of sparks is capped', () {
    final juice = Juice();
    for (var i = 0; i < 50; i++) {
      juice.burst(Offset.zero, Colors.white, count: 20);
    }
    expect(juice.sparks.length, lessThanOrEqualTo(80));
  });
}
