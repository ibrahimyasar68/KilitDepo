/// Küçük, bağımlılıksız CSV okuyucu (RFC 4180 + yaygın sapmalar).
///
/// - Tırnaklı alanlar, tırnak içinde `""` (kaçış), alan içinde satır sonu.
/// - Ayırıcı: başlık satırındaki (tırnak dışı) sayıya göre `,`, `;` veya
///   sekme otomatik seçilir.
/// - Dosya başındaki UTF-8 BOM ve `\r\n` / `\r` satır sonları.
/// - Tamamen boş satırlar atlanır.
///
/// [maxRows] aşılırsa [CsvTooLargeException] fırlatılır (kötü niyetli dev
/// dosyalara karşı).
abstract final class CsvParser {
  static List<List<String>> parse(String input, {int? maxRows}) {
    var text = input;
    if (text.startsWith('﻿')) text = text.substring(1);
    final delimiter = _detectDelimiter(text);

    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var fieldStarted = false;

    void endField() {
      row.add(field.toString());
      field.clear();
      fieldStarted = false;
    }

    void endRow() {
      endField();
      // Tamamen boş satır (tek boş alan) atlanır.
      if (!(row.length == 1 && row.first.isEmpty)) {
        rows.add(row);
        if (maxRows != null && rows.length > maxRows) {
          throw const CsvTooLargeException();
        }
      }
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
        continue;
      }
      if (c == '"' && !fieldStarted && field.isEmpty) {
        inQuotes = true;
        fieldStarted = true;
      } else if (c == delimiter) {
        endField();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      } else {
        field.write(c);
        fieldStarted = true;
      }
    }
    if (field.isNotEmpty || row.isNotEmpty || inQuotes) endRow();
    return rows;
  }

  /// İlk satırda tırnak dışındaki ayırıcı adaylarını sayar.
  static String _detectDelimiter(String text) {
    final counts = {',': 0, ';': 0, '\t': 0};
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') inQuotes = !inQuotes;
      if (!inQuotes && (c == '\n' || c == '\r')) break;
      if (!inQuotes && counts.containsKey(c)) counts[c] = counts[c]! + 1;
    }
    var best = ',';
    for (final e in counts.entries) {
      if (e.value > counts[best]!) best = e.key;
    }
    return best;
  }
}

class CsvTooLargeException implements Exception {
  const CsvTooLargeException();
}
