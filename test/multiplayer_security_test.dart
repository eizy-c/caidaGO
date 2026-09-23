import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/multiplayer/network/multiplayer_security.dart';

void main() {
  group('MultiplayerSecurity - Cifrado de Salas Públicas y Privadas', () {
    test('Cifra y descifra correctamente un mensaje de sala pública', () {
      const original = '{"type":"PLAYER_MOVE","data":{"card":"7_ESPADAS"}}';
      final encrypted = MultiplayerSecurity.encryptPayload(original);

      expect(encrypted, isNot(equals(original)));
      expect(encrypted.contains('_sec'), isTrue);
      expect(encrypted.contains('_enc'), isTrue);

      final decrypted = MultiplayerSecurity.decryptPayload(encrypted);
      expect(decrypted, equals(original));
    });

    test('Cifra y descifra sala privada usando PIN de 4 dígitos', () {
      const original = '{"type":"CHAT","text":"Buenas tardes"}';
      const pin = '4821';
      const roomId = 'RM-9921';

      final encrypted = MultiplayerSecurity.encryptPayload(
        original,
        pinCode: pin,
        roomId: roomId,
      );

      // Descifrar con el PIN correcto
      final decrypted = MultiplayerSecurity.decryptPayload(
        encrypted,
        pinCode: pin,
        roomId: roomId,
      );
      expect(decrypted, equals(original));

      // Intentar descifrar con PIN incorrecto debe fallar (retorna null)
      final failedAttempt = MultiplayerSecurity.decryptPayload(
        encrypted,
        pinCode: '0000',
        roomId: roomId,
      );
      expect(failedAttempt, isNull);
    });

    test('Maneja transparentemente mensajes en texto plano por compatibilidad', () {
      const plain = '{"type":"LEGACY_PING","data":{}}';
      final result = MultiplayerSecurity.decryptPayload(plain);
      expect(result, equals(plain));
    });
  });
}
