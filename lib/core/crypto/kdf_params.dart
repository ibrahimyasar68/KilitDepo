/// Argon2id anahtar türetme parametreleri.
///
/// Parametreler sarılmış DEK ile birlikte saklanır; böylece ileride
/// varsayılanlar güçlendirildiğinde eski kasalar hâlâ açılabilir.
class KdfParams {
  const KdfParams({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.hashLength,
  });

  factory KdfParams.fromJson(Map<String, dynamic> json) => KdfParams(
    memoryKiB: json['m'] as int,
    iterations: json['t'] as int,
    parallelism: json['p'] as int,
    hashLength: json['l'] as int,
  );

  /// Bellek miktarı (1 KiB bloklar).
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  /// Türetilen anahtarın uzunluğu (byte).
  final int hashLength;

  Map<String, dynamic> toJson() => {
    'alg': 'argon2id',
    'm': memoryKiB,
    't': iterations,
    'p': parallelism,
    'l': hashLength,
  };

  /// AAD olarak kullanılan kanonik gösterim. Parametrelerin saklandığı
  /// yerde sessizce değiştirilmesi DEK açma işlemini başarısız kılar.
  String get canonical =>
      'argon2id;m=$memoryKiB;t=$iterations;p=$parallelism;l=$hashLength';

  @override
  bool operator ==(Object other) =>
      other is KdfParams &&
      other.memoryKiB == memoryKiB &&
      other.iterations == iterations &&
      other.parallelism == parallelism &&
      other.hashLength == hashLength;

  @override
  int get hashCode =>
      Object.hash(memoryKiB, iterations, parallelism, hashLength);
}
