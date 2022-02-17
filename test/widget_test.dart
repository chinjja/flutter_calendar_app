import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  test('can call multiple first on a behavior subject', () async {
    final s = BehaviorSubject.seeded(1);
    expect(await s.first, 1);
    expect(await s.first, 1);
  });

  test('which obs emit?', () async {
    final o1 = PublishSubject<int>();
    final o2 = PublishSubject<String>();

    final o3 = o1.withLatestFrom(o2, (t, s) => '$t$s');
    expect(o3, emitsInOrder(['2A', '3A', '4B']));
    o1.add(1);
    o2.add('A');
    o1.add(2);
    o1.add(3);
    await Future.delayed(const Duration(milliseconds: 5));
    o2.add('B');
    o1.add(4);
  });

  test('which obs emit? 2', () async {
    final o1 = PublishSubject<int>();
    final o2 = PublishSubject<String>();

    final o3 = Rx.combineLatest2(o1, o2, (t, s) => '$t$s');
    expect(o3, emitsInOrder(['1A', '2A', '3A', '3B', '4B']));
    o1.add(1);
    await Future.delayed(const Duration(milliseconds: 5));
    o2.add('A');
    await Future.delayed(const Duration(milliseconds: 5));
    o1.add(2);
    await Future.delayed(const Duration(milliseconds: 5));
    o1.add(3);
    await Future.delayed(const Duration(milliseconds: 5));
    o2.add('B');
    await Future.delayed(const Duration(milliseconds: 5));
    o1.add(4);
  });
}
