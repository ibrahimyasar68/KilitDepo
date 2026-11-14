import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/unlock_attempt_limiter.dart';
import '../../../data/vault_session.dart';
import '../../../domain/repositories/vault_key_repository.dart';
import 'auth_providers.dart';

enum AuthStatus { initializing, needsSetup, locked, unlocked, error }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.lockoutUntil,
    this.previousVaultMissing = false,
  });

  const AuthState.initializing() : this(status: AuthStatus.initializing);

  final AuthStatus status;
  final bool biometricEnabled;
  final bool biometricAvailable;

  /// Hatalı denemeler nedeniyle ana şifre girişinin kapalı olduğu süre
  /// bitişi. null → bekleme yok.
  final DateTime? lockoutUntil;

  /// Kasa anahtar bilgileri bulundu ama veritabanı dosyası yoktu (ör. iOS'ta
  /// uygulama silinip yeniden kurulunca Keychain kalır, veri silinir).
  /// Kurulum ekranında kullanıcıya açıklama göstermek için.
  final bool previousVaultMissing;

  AuthState copyWith({
    AuthStatus? status,
    bool? biometricEnabled,
    bool? biometricAvailable,
    DateTime? lockoutUntil,
    bool clearLockout = false,
    bool? previousVaultMissing,
  }) => AuthState(
    status: status ?? this.status,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
    previousVaultMissing: previousVaultMissing ?? this.previousVaultMissing,
  );
}

enum UnlockResult {
  success,
  wrongPassword,
  lockedOut,
  corrupted,
  cancelled,
  error,
}

enum ChangePasswordResult { success, wrongCurrentPassword, lockedOut, error }

enum BiometricChangeResult {
  success,
  wrongPassword,
  lockedOut,
  unavailable,

  /// Biyometrik doğrulama iptal edildi veya donanım hatası.
  failed,
}

/// Kilitlenme nedeni.
enum LockReason {
  /// Kullanıcı "Kilitle" butonuna bastı: pano da hemen temizlenir.
  manual,

  /// Arka plana geçiş veya hareketsizlik: pano 30 sn kuralına bırakılır
  /// (aksi hâlde kopyalayıp başka uygulamaya geçmek mümkün olmazdı).
  automatic,
}

/// Kasa oluşturma sonucu.
enum CreateVaultResult { success, successWithoutBiometric }

/// Kimlik doğrulama durumu ve kilit/aç işlemleri.
///
/// Açık DEK yalnızca [vaultSessionProvider] içinde tutulur; durum
/// nesnesinde ASLA anahtar veya şifre bulunmaz.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_initialize);
    return const AuthState.initializing();
  }

  VaultKeyRepository get _repo => ref.read(vaultKeyRepositoryProvider);

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        _repo.isVaultInitialized(),
        _repo.isBiometricEnabled(),
        ref.read(biometricServiceProvider).isAvailable(),
        _limiter.lockedUntil(),
        Future<void>.delayed(ref.read(splashMinDurationProvider)),
      ]);
      var initialized = results[0] as bool;
      var orphaned = false;
      if (initialized && !await ref.read(vaultDatabaseExistsProvider)()) {
        // YETİM KASA: Anahtar bilgileri var ama veri dosyası yok. Veri
        // zaten silinmiştir (ör. iOS'ta yeniden kurulum: Keychain kalır,
        // uygulama verisi silinir) veya ilk kurulum veritabanı oluşmadan
        // kesilmiştir. Boş bir kasa açmak yerine anahtar bilgileri
        // temizlenir ve kurulum ekranı gösterilir. Silinen yalnızca artık
        // hiçbir veriyi açmayan bir anahtardır.
        await _repo.discardNewVault();
        await _limiter.reset();
        initialized = false;
        orphaned = true;
      }
      state = AuthState(
        status: initialized ? AuthStatus.locked : AuthStatus.needsSetup,
        biometricEnabled: initialized && (results[1] as bool),
        biometricAvailable: results[2] as bool,
        lockoutUntil: initialized ? results[3] as DateTime? : null,
        previousVaultMissing: orphaned,
      );
    } on Object {
      // Hata ayrıntısı hassas veri içerebileceği için loglanmaz.
      state = const AuthState(status: AuthStatus.error);
    }
  }

  /// Yeni kasa oluşturur ve açar.
  Future<CreateVaultResult> createVault(
    String masterPassword, {
    required bool enableBiometric,
  }) async {
    if (await _repo.isVaultInitialized()) {
      throw const VaultAlreadyExistsException();
    }
    final deleteDatabase = ref.read(vaultDatabaseDeleterProvider);
    // Önceki yarım kalmış bir kurulumdan kalan veritabanı dosyası varsa
    // anahtarı artık yoktur ve hiçbir zaman açılamaz: yeni kasanın
    // açılmasını engellememesi için temizlenir.
    await deleteDatabase();

    final dek = await _repo.createVault(masterPassword);
    try {
      // Oturum DEK'in sahipliğini alır ve şifreli veritabanını açar.
      await _session.open(dek);
    } catch (_) {
      // GERİ ALMA: Anahtar bilgileri yazıldı ama veritabanı açılamadı.
      // Yarım kasa bırakılmaz; kullanıcı kurulumu yeniden deneyebilir.
      // (Kasada henüz hiç kayıt olmadığı için veri kaybı yoktur.)
      await _ignoreErrors(_repo.discardNewVault);
      await _ignoreErrors(deleteDatabase);
      rethrow;
    }

    var biometricOk = false;
    if (enableBiometric && state.biometricAvailable) {
      try {
        await _repo.enableBiometric(_session.dek);
        biometricOk = true;
      } on Object {
        await _safeDisableBiometric();
      }
    }

    state = state.copyWith(
      status: AuthStatus.unlocked,
      biometricEnabled: biometricOk,
    );
    return enableBiometric && !biometricOk
        ? CreateVaultResult.successWithoutBiometric
        : CreateVaultResult.success;
  }

  Future<UnlockResult> unlockWithPassword(String masterPassword) async {
    // Bekleme süresi dolmadan anahtar türetme bile denenmez.
    final until = await _limiter.lockedUntil();
    if (until != null) {
      state = state.copyWith(lockoutUntil: until);
      return UnlockResult.lockedOut;
    }
    final SecretKeyData dek;
    try {
      dek = await _repo.unlockWithPassword(masterPassword);
    } on WrongMasterPasswordException {
      final next = await _limiter.recordFailure();
      state = next == null
          ? state.copyWith(clearLockout: true)
          : state.copyWith(lockoutUntil: next);
      return UnlockResult.wrongPassword;
    } on VaultKeyCorruptedException {
      return UnlockResult.corrupted;
    } on Object {
      return UnlockResult.error;
    }
    return _openSession(dek);
  }

  Future<UnlockResult> unlockWithBiometric() async {
    if (!state.biometricEnabled) return UnlockResult.error;
    final SecretKeyData? dek;
    try {
      dek = await _repo.unlockWithBiometric();
    } on BiometricCancelledException {
      // Kullanıcı vazgeçti: hata değil, sessizce ana şifreye dönülür.
      return UnlockResult.cancelled;
    } on Object {
      // Biyometri değişikliği, çok fazla deneme veya donanım hatası.
      return UnlockResult.error;
    }
    // Biyometrik anahtar yok (ör. silinmiş): gerçek bir sorun.
    if (dek == null) return UnlockResult.error;
    return _openSession(dek);
  }

  /// Kasayı kilitler: önce durum değişir (ekranlar kapanır), ardından
  /// veritabanı kapatılır ve anahtarlar sıfırlanır. Elle kilitlemede pano
  /// da hemen temizlenir; otomatik kilitte 30 sn kuralı geçerlidir.
  Future<void> lock({LockReason reason = LockReason.manual}) async {
    // Bekleyen silmeler vb. veritabanı kapanmadan tamamlanır.
    if (state.status == AuthStatus.unlocked) {
      await ref.read(beforeLockProvider).runAll();
    }
    if (state.status == AuthStatus.unlocked) {
      state = state.copyWith(status: AuthStatus.locked);
    }
    await _session.close();
    if (reason == LockReason.manual) {
      await ref.read(secureClipboardProvider).clearNow();
    }
  }

  /// Ana şifreyi değiştirir (DEK yeniden sarılır; kayıtlar yeniden
  /// şifrelenmez). Yanlış mevcut şifre hatalı deneme sayılır.
  Future<ChangePasswordResult> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final until = await _limiter.lockedUntil();
    if (until != null) {
      state = state.copyWith(lockoutUntil: until);
      return ChangePasswordResult.lockedOut;
    }
    try {
      await _repo.changeMasterPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _limiter.reset();
      state = state.copyWith(clearLockout: true);
      return ChangePasswordResult.success;
    } on WrongMasterPasswordException {
      final next = await _limiter.recordFailure();
      if (next != null) state = state.copyWith(lockoutUntil: next);
      return ChangePasswordResult.wrongCurrentPassword;
    } on Object {
      return ChangePasswordResult.error;
    }
  }

  /// Biyometrik girişi açar. GÜVENLİK: Ana şifre yeniden istenir; kilidi
  /// açık telefonu eline alan biri, ana şifreyi bilmeden kasaya yeni bir
  /// giriş yolu ekleyememelidir. Yanlış şifre hatalı deneme sayılır.
  Future<BiometricChangeResult> enableBiometric(String masterPassword) async {
    if (!state.biometricAvailable) return BiometricChangeResult.unavailable;
    final until = await _limiter.lockedUntil();
    if (until != null) {
      state = state.copyWith(lockoutUntil: until);
      return BiometricChangeResult.lockedOut;
    }
    final SecretKeyData dek;
    try {
      dek = await _repo.unlockWithPassword(masterPassword);
    } on WrongMasterPasswordException {
      final next = await _limiter.recordFailure();
      if (next != null) state = state.copyWith(lockoutUntil: next);
      return BiometricChangeResult.wrongPassword;
    } on Object {
      return BiometricChangeResult.failed;
    }
    try {
      // Android'de bu yazma işlemi biyometrik istemi tetikler.
      await _repo.enableBiometric(dek);
    } on Object {
      await _safeDisableBiometric();
      return BiometricChangeResult.failed;
    } finally {
      dek.destroy();
    }
    await _limiter.reset();
    state = state.copyWith(biometricEnabled: true, clearLockout: true);
    return BiometricChangeResult.success;
  }

  /// Biyometrik girişi kapatır ve DEK kopyasını siler.
  Future<void> disableBiometric() async {
    await _safeDisableBiometric();
    state = state.copyWith(biometricEnabled: false);
  }

  VaultSession get _session => ref.read(vaultSessionProvider);

  UnlockAttemptLimiter get _limiter => ref.read(unlockAttemptLimiterProvider);

  Future<UnlockResult> _openSession(SecretKeyData dek) async {
    try {
      await _session.open(dek);
    } on Object {
      // Ör. SQLCipher yüklenemedi veya veritabanı açılamadı.
      return UnlockResult.error;
    }
    await _limiter.reset();
    state = state.copyWith(status: AuthStatus.unlocked, clearLockout: true);
    return UnlockResult.success;
  }

  Future<void> _ignoreErrors(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Geri alma adımı başarısız olsa da asıl hata kullanıcıya iletilir.
    }
  }

  Future<void> _safeDisableBiometric() async {
    try {
      await _repo.disableBiometric();
    } on Object {
      // Yoksay: biyometrik kopya zaten yazılamamış olabilir.
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
