import 'package:atombrand_app/features/auth/auth_field.dart';
import 'package:atombrand_app/features/auth/auth_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password strength scores length, case mix, digits and symbols', () {
    expect(passwordStrength('').score, 0);
    expect(passwordStrength('abc').score, 1);
    expect(passwordStrength('abcdefgh').score, 1);
    expect(passwordStrength('Abcdefgh').score, 2);
    expect(passwordStrength('Orbit2048').score, 3);
    expect(passwordStrength('Orbit2048').hint, 'Add a symbol to make it stronger');
    expect(passwordStrength('Orbit-2048').score, 4);
  });

  test('login accepts a valid email or Pakistani mobile only', () {
    expect(loginValidator('alex@brand.pk'), isNull);
    expect(loginValidator('0300 1234567'), isNull);
    expect(loginValidator('alex@brand'), isNotNull);
    expect(loginValidator(''), isNotNull);
  });

  test('optional phone may be empty but not malformed', () {
    expect(phoneValidator('', required: false), isNull);
    expect(phoneValidator('12345', required: false), isNotNull);
  });
}
