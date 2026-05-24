/// Parse OCR text จาก Slip โอนเงินไทย
/// รองรับ: PromptPay, KBank, SCB, BBL, KTB, TTB, BAY
class SlipParser {
  static SlipParseResult parse(String rawText) {
    final text = rawText.trim();

    return SlipParseResult(
      amount: _parseAmount(text),
      date: _parseDate(text),
      note: _parseNote(text),
      rawText: text,
    );
  }

  // ─── Amount ──────────────────────────────────────────────────────────────

  static double? _parseAmount(String text) {
    // Pattern ต่างๆ ที่พบใน Slip ไทย
    final patterns = [
      // "จำนวน 1,250.00 บาท" หรือ "จำนวนเงิน 250.00 บาท"
      RegExp(r'จำนวน(?:เงิน)?\s*([\d,]+\.?\d*)\s*บาท'),
      // "฿1,250.00" หรือ "฿ 250"
      RegExp(r'฿\s*([\d,]+\.?\d*)'),
      // "1,250.00 บาท" (ตัวเลขตามด้วยบาท)
      RegExp(r'([\d,]+\.\d{2})\s*บาท'),
      // "THB 1,250.00"
      RegExp(r'THB\s*([\d,]+\.?\d*)'),
      // "Amount: 1250.00"
      RegExp(r'[Aa]mount[:\s]+([\d,]+\.?\d*)'),
      // ตัวเลขขนาดใหญ่ที่น่าจะเป็นจำนวนเงิน (fallback)
      RegExp(r'\b(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(raw);
        if (value != null && value > 0 && value < 10000000) {
          return value;
        }
      }
    }
    return null;
  }

  // ─── Date ────────────────────────────────────────────────────────────────

  static DateTime? _parseDate(String text) {
    // "23 พ.ค. 2568" หรือ "23 พฤษภาคม 2568"
    final thaiMonthsShort = {
      'ม.ค.': 1, 'ก.พ.': 2, 'มี.ค.': 3, 'เม.ย.': 4,
      'พ.ค.': 5, 'มิ.ย.': 6, 'ก.ค.': 7, 'ส.ค.': 8,
      'ก.ย.': 9, 'ต.ค.': 10, 'พ.ย.': 11, 'ธ.ค.': 12,
    };
    final thaiMonthsFull = {
      'มกราคม': 1, 'กุมภาพันธ์': 2, 'มีนาคม': 3, 'เมษายน': 4,
      'พฤษภาคม': 5, 'มิถุนายน': 6, 'กรกฎาคม': 7, 'สิงหาคม': 8,
      'กันยายน': 9, 'ตุลาคม': 10, 'พฤศจิกายน': 11, 'ธันวาคม': 12,
    };

    // ลอง short month
    for (final entry in thaiMonthsShort.entries) {
      final pattern = RegExp(r'(\d{1,2})\s*' + RegExp.escape(entry.key) + r'\s*(\d{4})');
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final year = int.parse(match.group(2)!) - 543; // พ.ศ. → ค.ศ.
        return DateTime(year, entry.value, day);
      }
    }

    // ลอง full month
    for (final entry in thaiMonthsFull.entries) {
      final pattern = RegExp(r'(\d{1,2})\s*' + entry.key + r'\s*(\d{4})');
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final year = int.parse(match.group(2)!) - 543;
        return DateTime(year, entry.value, day);
      }
    }

    // "2024-05-23" หรือ "23/05/2024" หรือ "23/05/67"
    final patterns = [
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
      RegExp(r'(\d{2})/(\d{2})/(\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern.pattern.startsWith(r'(\d{4})')) {
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          } else {
            int year = int.parse(match.group(3)!);
            if (year < 100) year += (year > 50 ? 1900 : 2000);
            if (year > 2500) year -= 543; // พ.ศ.
            return DateTime(
              year,
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          }
        } catch (_) {}
      }
    }

    return null;
  }

  // ─── Note / Memo ─────────────────────────────────────────────────────────

  static String? _parseNote(String text) {
    final patterns = [
      RegExp(r'บันทึก[:\s]+(.+)', caseSensitive: false),
      RegExp(r'หมายเหตุ[:\s]+(.+)', caseSensitive: false),
      RegExp(r'[Mm]emo[:\s]+(.+)'),
      RegExp(r'[Nn]ote[:\s]+(.+)'),
      RegExp(r'[Rr]ef(?:erence)?[:\s]+(.+)'),
      RegExp(r'ข้อความ[:\s]+(.+)'),
      RegExp(r'รายละเอียด[:\s]+(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final note = match.group(1)?.trim();
        if (note != null && note.isNotEmpty && note.length < 200) {
          return note;
        }
      }
    }
    return null;
  }
}

class SlipParseResult {
  final double? amount;
  final DateTime? date;
  final String? note;
  final String rawText;

  const SlipParseResult({
    this.amount,
    this.date,
    this.note,
    required this.rawText,
  });

  bool get isValid => amount != null && amount! > 0;

  @override
  String toString() =>
      'SlipParseResult(amount: $amount, date: $date, note: $note)';
}
