// URL server Laravel
const String kBaseUrl = 'https://mini-stesy.monitoring4system.com';

const String kApiPrefix = '/api/v1/mobile';

class ApiEndpoints {
  // ── Auth ────────────────────────────────────────────
  static const String login  = '$kApiPrefix/auth/login';
  static const String logout = '$kApiPrefix/auth/logout'; 
  static const String me     = '$kApiPrefix/auth/me';
  static const String fcmRegister = '$kApiPrefix/fcm/register';

  // ── Beranda ─────────────────────────────────────────
  static const String berandaInfo = '$kApiPrefix/beranda/info';

  // ── Peta ────────────────────────────────────────────
  static const String petaPoints = '$kApiPrefix/peta/points';

  // ── Realtime ────────────────────────────────────────
  static const String realtimeDevices    = '$kApiPrefix/realtime/devices';
  static const String realtimeMqttConfig = '$kApiPrefix/realtime/mqtt-config';
  static String realtimeData(String id)  => '$kApiPrefix/realtime/data/$id';

  // ── Data Perangkat ───────────────────────────────────
  static const String dataPerangkat          = '$kApiPrefix/data-perangkat';
  static String dataPerangkatDetail(String id) => '$kApiPrefix/data-perangkat/$id';

  // ── Analisa ─────────────────────────────────────────
  static String analisaIndex(String id) => '$kApiPrefix/analisa/$id';
  static String analisaData(String id)  => '$kApiPrefix/analisa/$id/data';
}
