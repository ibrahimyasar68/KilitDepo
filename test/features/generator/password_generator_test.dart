import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/features/generator/application/password_generator.dart';

void main() {
  final gen = PasswordGenerator();

  bool hasAny(String s, String set) => s.split('').any(set.contains);

  test('varsayılan: 20 karakter, tüm gruplardan en az bir karakter', () {
    for (var i = 0; i < 200; i++) {
      final p = gen.generate(const GeneratorOptions());
      expect(p.length, 20);
      expect(hasAny(p, PasswordGenerator.upper), isTrue);
      expect(hasAny(p, PasswordGenerator.lower), isTrue);
      expect(hasAny(p, PasswordGenerator.digitChars), isTrue);
      expect(hasAny(p, PasswordGenerator.symbolChars), isTrue);
    }
  });

  test('uzunluk 8–64 aralığına kırpılır', () {
    expect(gen.generate(const GeneratorOptions(length: 3)).length, 8);
    expect(gen.generate(const GeneratorOptions(length: 64)).length, 64);
    expect(gen.generate(const GeneratorOptions(length: 500)).length, 64);
  });

  test('yalnızca seçilen gruplar kullanılır', () {
    const o = GeneratorOptions(uppercase: false, symbols: false, length: 40);
    for (var i = 0; i < 100; i++) {
      final p = gen.generate(o);
      expect(hasAny(p, PasswordGenerator.upper), isFalse);
      expect(hasAny(p, PasswordGenerator.symbolChars), isFalse);
      expect(hasAny(p, PasswordGenerator.digitChars), isTrue);
    }
  });

  test('karışabilecek karakterler hariç tutulur', () {
    const o = GeneratorOptions(excludeAmbiguous: true, length: 64);
    for (var i = 0; i < 300; i++) {
      expect(hasAny(gen.generate(o), PasswordGenerator.ambiguous), isFalse);
    }
  });

  test('hiç grup seçilmezse hata', () {
    expect(
      () => gen.generate(
        const GeneratorOptions(
          uppercase: false,
          lowercase: false,
          digits: false,
          symbols: false,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('üretilen şifreler tekrar etmez', () {
    final set = {
      for (var i = 0; i < 1000; i++) gen.generate(const GeneratorOptions()),
    };
    expect(set.length, 1000);
  });

  test('kabaca eşit dağılım (rakamlar, 10.000 örnek)', () {
    const o = GeneratorOptions(
      uppercase: false,
      lowercase: false,
      symbols: false,
      length: 10,
    );
    final counts = <String, int>{};
    for (var i = 0; i < 1000; i++) {
      for (final c in gen.generate(o).split('')) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    expect(counts.keys.length, 10);
    // Beklenen ~1000; geniş tolerans (istatistiksel test, kararlı olmalı).
    for (final n in counts.values) {
      expect(n, inInclusiveRange(800, 1200));
    }
  });
}
