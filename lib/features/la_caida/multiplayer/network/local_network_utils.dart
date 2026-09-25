import 'dart:io';

/// Utilidades de red local para descubrir interfaces de red e IP local
class LocalNetworkUtils {
  LocalNetworkUtils._();

  /// Obtiene la dirección IPv4 local más adecuada del dispositivo (no loopback)
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            // Preferir rangos privados clásicos (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
            final ip = address.address;
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
              return ip;
            }
          }
        }
      }

      // Si no encontramos IP privada específica, devolver la primera disponible
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  /// Valida si una cadena tiene formato de 4 dígitos numéricos para un PIN
  static bool isValidPin(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin.trim());
  }

  /// Genera un PIN aleatorio de 4 dígitos
  static String generateRandomPin() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final pinNum = (now % 9000) + 1000;
    return pinNum.toString();
  }

  /// Genera un ID de sala de 5 caracteres alfanuméricos en mayúsculas (ej: K7X9B)
  static String generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = (now ^ (now >> 7));
    var n = rnd.abs();
    final buffer = StringBuffer();
    for (int i = 0; i < 5; i++) {
      buffer.write(chars[n % chars.length]);
      n = (n ~/ chars.length) ^ (DateTime.now().microsecond + i * 31);
    }
    return buffer.toString();
  }
}
