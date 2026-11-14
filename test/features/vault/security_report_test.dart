import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/vault/application/security_report.dart';
import 'package:kilitdepo/features/vault/application/vault_providers.dart';

import '../../helpers/fake_vault_repository.dart';

void main() {
  test('zayıf şifreler bulunur', () {
    final r = analyzePasswords([
      (id: 1, password: '123456'),
      (id: 2, password: 'Kx9#mQ2!vL7@pR4zT8&w'),
      (id: 3, password: 'password'),
    ]);
    expect(r.weakIds, [1, 3]);
    expect(r.reusedGroups, isEmpty);
  });

  test('tekrar kullanılan şifreler gruplanır', () {
    final r = analyzePasswords([
      (id: 1, password: 'Aynı-Güçlü-Şifre-2026!'),
      (id: 2, password: 'Başka-Güçlü-Şifre-77#'),
      (id: 3, password: 'Aynı-Güçlü-Şifre-2026!'),
      (id: 4, password: 'Aynı-Güçlü-Şifre-2026!'),
    ]);
    expect(r.weakIds, isEmpty);
    expect(r.reusedGroups, [
      [1, 3, 4],
    ]);
    expect(r.issueCount, 3);
  });

  test('aynı kayıt hem zayıf hem tekrar ise bir kez sayılır', () {
    final r = analyzePasswords([
      (id: 1, password: 'abc'),
      (id: 2, password: 'abc'),
    ]);
    expect(r.weakIds, [1, 2]);
    expect(r.reusedGroups, hasLength(1));
    expect(r.issueCount, 2);
  });

  test('sorun yoksa temiz', () {
    final r = analyzePasswords([(id: 1, password: 'Kx9#mQ2!vL7@pR4zT8&w')]);
    expect(r.isClean, isTrue);
    expect(analyzePasswords([]).isClean, isTrue);
  });

  test('favori değişikliği raporu yeniden hesaplatmaz; şifre değişikliği '
      'hesaplatır', () async {
    final repo = FakeVaultRepository();
    final container = ProviderContainer(
      overrides: [vaultRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(securityReportProvider, (_, _) {});
    addTearDown(sub.close);

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    final id = await repo.addEntry(
      const EntryDraft(title: 'Banka', username: 'a', password: '123456'),
    );
    await settle();
    await container.read(securityReportProvider.future);
    final afterAdd = repo.revealAllCalls;
    expect(container.read(securityReportProvider).value!.weakIds, [id]);

    await repo.setFavorite(id, isFavorite: true);
    await settle();
    await container.read(securityReportProvider.future);
    expect(repo.revealAllCalls, afterAdd);

    await repo.updateEntry(
      id,
      const EntryDraft(
        title: 'Banka',
        username: 'a',
        password: 'Kx9#mQ2!vL7@pR4zT8&w',
      ),
    );
    await settle();
    final report = await container.read(securityReportProvider.future);
    expect(repo.revealAllCalls, afterAdd + 1);
    expect(report.isClean, isTrue);
  });
}
