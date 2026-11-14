import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_exceptions.dart';
import 'package:kilitdepo/core/widgets/entry_avatar.dart';
import 'package:kilitdepo/data/repositories/vault_key_repository_impl.dart';
import 'package:kilitdepo/domain/entities/entry_category.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/features/auth/application/auth_controller.dart';
import 'package:kilitdepo/features/auth/presentation/login_screen.dart';
import 'package:kilitdepo/features/home/home_shell.dart';
import 'package:kilitdepo/features/vault/application/save_error.dart';
import 'package:kilitdepo/features/vault/presentation/entry_edit_screen.dart';
import 'package:kilitdepo/features/vault/presentation/vault_list_screen.dart';
import 'package:kilitdepo/features/vault/presentation/widgets/vault_ui.dart';

import '../helpers/fake_vault_repository.dart';
import '../helpers/test_app.dart';
import 'design_test.dart' show seeded;

const unlocked = AuthState(status: AuthStatus.unlocked);

/// Kayıt eklemede hata veren sahte depo.
class FailingRepository extends FakeVaultRepository {
  FailingRepository(this.error);

  final Object error;

  @override
  Future<int> addEntry(EntryDraft d) async => throw error;
}

PlatformException androidError(int code) => PlatformException(
  code: 'Exception encountered',
  message: 'Biometric authentication error [$code]: x',
);

void main() {
  group('Biyometri: iptal ile hata ayrımı', () {
    test('Android 5/10/13 ve iOS -128 iptaldir; diğerleri hata', () {
      for (final c in [5, 10, 13]) {
        expect(isBiometricCancellation(androidError(c)), isTrue, reason: '$c');
      }
      for (final c in [7, 9, 1, 11]) {
        expect(isBiometricCancellation(androidError(c)), isFalse, reason: '$c');
      }
      expect(
        isBiometricCancellation(
          PlatformException(
            code: 'Unexpected security result code',
            details: -128,
          ),
        ),
        isTrue,
      );
      expect(isBiometricCancellation(PlatformException(code: 'x')), isFalse);
    });

    testWidgets('gerçek hatada (ör. çok fazla deneme) uyarı gösterilir', (
      tester,
    ) async {
      final (fake, _) = await pumpApp(
        tester,
        const AuthState(
          status: AuthStatus.locked,
          biometricAvailable: true,
          biometricEnabled: true,
        ),
      );
      fake.biometricCompleter = Completer<UnlockResult>()
        ..complete(UnlockResult.error);
      await tester.tap(find.byKey(LoginScreen.biometricButtonKey));
      await tester.pumpAndSettle();
      expect(find.text(l10n.loginBiometricFailed), findsOneWidget);
    });
  });

  test('alt menüde "Şifre Üretici"', () {
    expect(l10n.navGenerator, 'Şifre Üretici');
  });

  group('Kayıt hatasının nedeni', () {
    test('hata türleri doğru sınıflanır (gizli veri içermez)', () {
      expect(
        classifySaveError(StateError('Kasa kilitli.')).kind,
        SaveFailureKind.locked,
      );
      expect(
        classifySaveError(ArgumentError('x')).kind,
        SaveFailureKind.invalid,
      );
      expect(
        classifySaveError(const DecryptionFailedException()).kind,
        SaveFailureKind.crypto,
      );
      final unknown = classifySaveError(const FormatException('gizli-şifre'));
      expect(unknown.kind, SaveFailureKind.unknown);
      expect(unknown.detail, 'FormatException');
      expect(unknown.detail.contains('gizli'), isFalse);
    });

    testWidgets('kaydedilemezse nedeni bildirimde yazar, form açık kalır', (
      tester,
    ) async {
      await pumpApp(
        tester,
        unlocked,
        repository: FailingRepository(StateError('Kasa kilitli.')),
      );
      await tester.tap(find.byKey(VaultListScreen.addButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(EntryEditScreen.titleKey), 'Yeni');
      await tester.enterText(find.byKey(EntryEditScreen.passwordKey), 'Pw-1');
      await tapVisible(tester, find.byKey(EntryEditScreen.saveKey));
      expect(find.text(l10n.entrySaveErrorLocked), findsOneWidget);
      expect(find.byType(EntryEditScreen), findsOneWidget);
    });
  });

  group('Favoriler', () {
    testWidgets('küçük kutu; simge seçilmemişse kategori simgesi', (
      tester,
    ) async {
      final repo = await seeded();
      await repo.addEntry(
        const EntryDraft(
          title: 'Banka',
          username: 'b',
          password: 'Pw-Banka-1',
          category: EntryCategory.bank,
          isFavorite: true,
        ),
      );
      await pumpApp(tester, unlocked, repository: repo);
      final tile = find.byKey(const Key('favorite_4'));
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile).height, lessThanOrEqualTo(56));
      expect(
        tester
            .widget<EntryAvatar>(
              find.descendant(of: tile, matching: find.byType(EntryAvatar)),
            )
            .fallbackIcon,
        EntryCategory.bank.icon,
      );
      expect(
        find.descendant(
          of: tile,
          matching: find.byIcon(Icons.account_balance_outlined),
        ),
        findsOneWidget,
      );
      // Kasa sekmesi var (gezinme bozulmadı).
      expect(find.byKey(HomeShell.vaultTabKey), findsOneWidget);
    });
  });
}
