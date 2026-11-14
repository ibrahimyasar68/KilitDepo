import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/features/auth/application/password_strength.dart';

void main() {
  PasswordStrength s(String p) => PasswordStrengthEstimator.estimate(p);

  test('boş ve kısa şifreler çok zayıf', () {
    expect(s(''), PasswordStrength.veryWeak);
    expect(s('abc'), PasswordStrength.veryWeak);
  });

  test('yaygın kalıplar cezalandırılır', () {
    expect(s('password1234').index, lessThan(PasswordStrength.fair.index));
    expect(s('aaaaaaaaaaaa'), PasswordStrength.veryWeak);
    expect(s('abcdefghijkl').index, lessThan(PasswordStrength.fair.index));
  });

  test('uzun ve çeşitli şifreler güçlü', () {
    expect(
      s('Kx9#mQ2!vL7@pR4z').index,
      greaterThanOrEqualTo(PasswordStrength.strong.index),
    );
    expect(
      s('Mavi-Kedi.Uçan*Bulut_42!').index,
      greaterThanOrEqualTo(PasswordStrength.strong.index),
    );
  });

  test('uzunluk arttıkça güç azalmaz', () {
    expect(
      PasswordStrengthEstimator.entropyBits('Tr7#kd9Lq2'),
      lessThan(PasswordStrengthEstimator.entropyBits('Tr7#kd9Lq2Wm5!')),
    );
  });
}
