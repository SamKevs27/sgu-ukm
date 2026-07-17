import 'dart:convert';

/// JSON payload encoded in meeting QR codes: `clubId`, `meetingId`, `token`.
class QrAttendancePayload {
  const QrAttendancePayload({
    required this.clubId,
    required this.meetingId,
    required this.token,
  });

  final String clubId;
  final String meetingId;
  final String token;

  static QrAttendancePayload parse(String raw) {
    final trimmed = raw.trim();
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('QR payload must be a JSON object');
      }
      map = decoded;
    } on FormatException {
      throw const FormatException('Invalid QR format');
    }
    final clubId = map['clubId']?.toString() ?? '';
    final meetingId = map['meetingId']?.toString() ?? '';
    final token = map['token']?.toString() ?? '';
    if (clubId.isEmpty || meetingId.isEmpty || token.isEmpty) {
      throw const FormatException('Incomplete attendance QR');
    }
    return QrAttendancePayload(
      clubId: clubId,
      meetingId: meetingId,
      token: token,
    );
  }
}
