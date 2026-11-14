import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/vault_session.dart';

void main() {
  final crypto = CryptoService();

  test(
    'açılınca anahtarlar ve veritabanı hazır, kapanınca temizlenir',
    () async {
      late AppDatabase db;
      List<int>? receivedKey;
      final session = VaultSession(
        crypto: crypto,
        openDatabase: (key) async {
          receivedKey = List.of(key.bytes);
          return db = AppDatabase(NativeDatabase.memory());
        },
      );
      final dek = crypto.generateDek();
      final subkeys = await crypto.deriveSubkeys(dek);

      await session.open(dek);
      expect(session.isOpen, isTrue);
      // Veritabanına DEK'in kendisi değil, HKDF alt anahtarı verilir.
      expect(receivedKey, subkeys.databaseKey.bytes);
      expect(receivedKey, isNot(dek.bytes));
      expect(session.fieldKey.bytes, subkeys.fieldKey.bytes);
      await db.customSelect('SELECT 1').get();

      await session.close();
      expect(session.isOpen, isFalse);
      expect(dek.isDestroyed, isTrue);
      expect(() => session.dek, throwsStateError);
      expect(() => session.fieldKey, throwsStateError);
      expect(() => session.database, throwsStateError);
    },
  );

  test('veritabanı açılamazsa DEK sıfırlanır ve hata yükselir', () async {
    final session = VaultSession(
      crypto: crypto,
      openDatabase: (_) async => throw StateError('açılamadı'),
    );
    final dek = crypto.generateDek();
    await expectLater(session.open(dek), throwsStateError);
    expect(session.isOpen, isFalse);
    expect(dek.isDestroyed, isTrue);
  });
}
