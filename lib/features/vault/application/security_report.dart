import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/password_entry.dart';
import '../../auth/application/password_strength.dart';
import 'vault_providers.dart';

/// Güvenlik raporu: yalnızca kayıt kimlikleri tutulur, şifreler DEĞİL.
@immutable
class SecurityReport {
  const SecurityReport({
    required this.weakIds,
    required this.reusedGroups,
    this.totalCount = 0,
  });

  static const empty = SecurityReport(weakIds: [], reusedGroups: []);

  /// İncelenen toplam kayıt sayısı.
  final int totalCount;

  /// 0–100 güvenlik puanı: uyarı almayan kayıtların oranı. Kayıt yoksa 100.
  int get score => totalCount == 0
      ? 100
      : (100 * (totalCount - issueCount) / totalCount).round();

  /// Zayıf şifreli kayıtlar.
  final List<int> weakIds;

  /// Aynı şifreyi paylaşan kayıt grupları (her grup ≥ 2 kayıt).
  final List<List<int>> reusedGroups;

  /// Uyarı alan farklı kayıt sayısı.
  int get issueCount => {...weakIds, for (final g in reusedGroups) ...g}.length;

  bool get isClean => weakIds.isEmpty && reusedGroups.isEmpty;
}

/// Zayıf: güç göstergesinde "Çok zayıf" veya "Zayıf".
bool isWeakPassword(String password) =>
    PasswordStrengthEstimator.estimate(password).index <=
    PasswordStrength.weak.index;

/// Şifreleri analiz eder. Çözülmüş şifreler yalnızca bu fonksiyon
/// çalışırken bellekte bulunur; sonuçta yalnızca kimlikler kalır.
SecurityReport analyzePasswords(List<({int id, String password})> items) {
  final weak = <int>[];
  final byPassword = <String, List<int>>{};
  for (final item in items) {
    if (isWeakPassword(item.password)) weak.add(item.id);
    (byPassword[item.password] ??= []).add(item.id);
  }
  final reused = byPassword.values.where((ids) => ids.length > 1).toList();
  byPassword.clear();
  return SecurityReport(
    weakIds: weak,
    reusedGroups: reused,
    totalCount: items.length,
  );
}

/// Kayıt kümesinin ve son güncelleme zamanlarının özeti (gizli veri içermez).
String? _passwordRevision(List<EntrySummary>? entries) => entries == null
    ? null
    : [for (final e in entries) '${e.id}:${e.updatedAt.microsecondsSinceEpoch}']
          .join(',');

/// Kayıtlar değiştikçe yeniden hesaplanan rapor.
final securityReportProvider = FutureProvider.autoDispose<SecurityReport>((
  ref,
) async {
  // Yalnızca şifreyi etkileyebilecek değişikliklerde (ekleme, silme,
  // düzenleme, içe aktarma) yeniden hesapla. Favori değişikliği
  // `updatedAt`'i değiştirmediği için tüm şifreleri yeniden çözdürmez;
  // böylece çözülmüş şifreler bellekte gereğinden sık bulunmaz.
  ref.watch(entriesProvider.select((async) => _passwordRevision(async.value)));
  final repo = ref.watch(vaultRepositoryProvider);
  if (repo == null) return SecurityReport.empty;
  return analyzePasswords(await repo.revealAllPasswords());
});

/// Bir kaydın güvenlik sorunları (liste rozeti ve detay uyarısı için).
@immutable
class EntryIssues {
  const EntryIssues({required this.weak, required this.reusedWith});

  final bool weak;

  /// Aynı şifreyi kullanan diğer kayıtların kimlikleri.
  final List<int> reusedWith;

  bool get reused => reusedWith.isNotEmpty;
}

/// Kayıt kimliği → sorunlar. Rapordan türetilir; ek şifre çözülmez.
final entryIssuesProvider = Provider.autoDispose<Map<int, EntryIssues>>((ref) {
  final report = ref.watch(securityReportProvider).value;
  if (report == null || report.isClean) return const {};
  final weak = report.weakIds.toSet();
  final reused = <int, List<int>>{
    for (final g in report.reusedGroups)
      for (final id in g)
        id: [
          for (final o in g)
            if (o != id) o,
        ],
  };
  return {
    for (final id in {...weak, ...reused.keys})
      id: EntryIssues(weak: weak.contains(id), reusedWith: reused[id] ?? []),
  };
});
