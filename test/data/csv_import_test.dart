import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilitdepo/core/crypto/crypto_service.dart';
import 'package:kilitdepo/data/database/app_database.dart';
import 'package:kilitdepo/data/repositories/vault_repository_impl.dart';
import 'package:kilitdepo/domain/entities/password_entry.dart';
import 'package:kilitdepo/data/import/csv_import.dart';
import 'package:kilitdepo/data/import/csv_parser.dart';

void main() {
  group('CsvParser', () {
    test('tırnak, kaçış, alan içinde satır sonu, CRLF', () {
      final rows = CsvParser.parse(
        'a,b,c\r\n"x, y","he said ""hi""","satır1\nsatır2"\r\n',
      );
      expect(rows, [
        ['a', 'b', 'c'],
        ['x, y', 'he said "hi"', 'satır1\nsatır2'],
      ]);
    });

    test('BOM atlanır; ; ve sekme ayırıcı algılanır; boş satır atlanır', () {
      expect(CsvParser.parse('﻿a;b\n1;2\n\n'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
      expect(CsvParser.parse('a\tb\n1\t2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('satır sınırı aşılırsa reddedilir', () {
      final big = List.generate(20, (i) => 'r$i').join('\n');
      expect(
        () => CsvParser.parse(big, maxRows: 10),
        throwsA(isA<CsvTooLargeException>()),
      );
    });
  });

  group('Biçimler', () {
    CsvImportParse parse(String s) => CsvImporter.parse(s);

    test('Chrome', () {
      final r = parse(
        'name,url,username,password,note\n'
        'Gmail,https://mail.google.com,ali@ornek.com,Gizli-1,not\n',
      );
      expect(r.format, CsvImportFormat.chrome);
      final c = r.candidates.single;
      expect(
        (c.title, c.username, c.password, c.url, c.notes),
        ('Gmail', 'ali@ornek.com', 'Gizli-1', 'https://mail.google.com', 'not'),
      );
    });

    test('Firefox: başlık adresten türetilir', () {
      final r = parse(
        '"url","username","password","httpRealm","formActionOrigin","guid",'
        '"timeCreated","timeLastUsed","timePasswordChanged"\n'
        '"https://www.ornek.com/giris","veli","Pw-2","","","{1}","1","1","1"\n',
      );
      expect(r.format, CsvImportFormat.firefox);
      expect(r.candidates.single.title, 'ornek.com');
    });

    test('Apple: TOTP aktarılmaz, sayılır', () {
      final r = parse(
        'Title,URL,Username,Password,Notes,OTPAuth\n'
        'Banka,https://banka.com,a,Pw-3,,otpauth://totp/x?secret=ABC\n'
        'Site,https://site.com,b,Pw-4,,\n',
      );
      expect(r.format, CsvImportFormat.apple);
      expect(r.totpDropped, 1);
      expect(r.candidates, hasLength(2));
      expect(
        r.candidates.every((c) => !(c.notes ?? '').contains('otpauth')),
        isTrue,
      );
    });

    test('Bitwarden: favori; şifresiz (not) satır atlanır', () {
      final r = parse(
        'folder,favorite,type,name,notes,fields,reprompt,login_uri,'
        'login_username,login_password,login_totp\n'
        ',1,login,Oyun,,,0,https://oyun.com,oyuncu,Pw-5,\n'
        ',,note,Gizli not,metin,,0,,,,\n',
      );
      expect(r.format, CsvImportFormat.bitwarden);
      expect(r.candidates.single.isFavorite, isTrue);
      expect(r.skippedNoPassword, 1);
    });

    test('1Password, Proton Pass, KeePassXC algılanır', () {
      expect(
        parse(
          'Title,Url,Username,Password,OTPAuth,Favorite,Archived,Tags,'
          'Notes\nA,u,b,p,,,,,\n',
        ).format,
        CsvImportFormat.onePassword,
      );
      final proton = parse(
        'type,name,url,email,username,password,note,totp,createTime,'
        'modifyTime,vault\nlogin,P,https://p.me,mail@p.me,,Pw-6,,,1,1,K\n',
      );
      expect(proton.format, CsvImportFormat.protonPass);
      // Kullanıcı adı yoksa e-posta kullanılır.
      expect(proton.candidates.single.username, 'mail@p.me');
      expect(
        parse(
          '"Group","Title","Username","Password","URL","Notes","TOTP",'
          '"Icon","Last Modified","Created"\n'
          '"Root","K","u","Pw-7","","","","0","x","y"\n',
        ).format,
        CsvImportFormat.keePass,
      );
    });

    test('Türkçe sütun adları (genel biçim, ; ayırıcı)', () {
      final r = parse('Başlık;Kullanıcı adı;Şifre;Adres\nEv;ben;Pw-8;\n');
      expect(r.format, CsvImportFormat.generic);
      expect(r.candidates.single.title, 'Ev');
    });

    test('hatalar: boş, sütun yok, çok büyük, kodlama yedeği', () {
      expect(
        () => parse('name,url\n'),
        throwsA(
          isA<CsvImportException>().having(
            (e) => e.reason,
            'reason',
            CsvImportError.empty,
          ),
        ),
      );
      expect(
        () => parse('a,b\n1,2\n'),
        throwsA(
          isA<CsvImportException>().having(
            (e) => e.reason,
            'reason',
            CsvImportError.missingColumns,
          ),
        ),
      );
      expect(
        () => CsvImporter.parseBytes(Uint8List(CsvImporter.maxBytes + 1)),
        throwsA(
          isA<CsvImportException>().having(
            (e) => e.reason,
            'reason',
            CsvImportError.tooLarge,
          ),
        ),
      );
      // UTF-8 olmayan (Latin-1) dosya da okunur.
      final latin = Uint8List.fromList(
        latin1.encode('name,url,username,password\nCafé,u,x,Pw-9\n'),
      );
      expect(CsvImporter.parseBytes(latin).candidates.single.title, 'Café');
    });
  });

  test('toplu ekleme tek işlem: biri geçersizse hiçbiri eklenmez', () async {
    final crypto = CryptoService();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = VaultRepositoryImpl(
      db: db,
      fieldKey: crypto.generateDek(),
      crypto: crypto,
    );
    await expectLater(
      repo.addEntries(const [
        EntryDraft(title: 'A', username: '', password: 'Pw-1'),
        EntryDraft(title: 'B', username: '', password: ''),
      ]),
      throwsArgumentError,
    );
    expect(await repo.watchEntries().first, isEmpty);
    expect(
      await repo.addEntries(const [
        EntryDraft(title: 'A', username: '', password: 'Pw-1'),
        EntryDraft(title: 'B', username: '', password: 'Pw-2', notes: 'gizli'),
      ]),
      2,
    );
    final rows = await db.customSelect('SELECT notes_enc FROM entries').get();
    // Notlar alan düzeyinde şifreli saklanır.
    expect(
      rows.any((r) => '${r.data['notes_enc']}'.contains('gizli')),
      isFalse,
    );
  });
}
