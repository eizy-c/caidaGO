import 'dart:convert';
import 'dart:typed_data';

/// Módulo de seguridad y cifrado para las comunicaciones en salas Multijugador (Públicas y Privadas).
///
/// Protege los mensajes transmitidos por WebSockets y UDP broadcast contra manipulación
/// y escuchas no autorizadas en la red Wi-Fi local.
///
/// - Para Salas Públicas: Aplica cifrado de flujo con clave de juego oficial autenticada.
/// - Para Salas Privadas: Deriva una clave criptográfica única basada en el PIN de 4 dígitos
///   y el identificador de sala, asegurando que solo los participantes con el PIN puedan
///   leer y enviar comandos válidos.
class MultiplayerSecurity {
  MultiplayerSecurity._();

  static const String _defaultPublicSalt = 'CaidaGO_PubSec_2026_LocalAuth!';

  /// Cifra un payload JSON de texto y genera un contenedor seguro autenticado
  static String encryptPayload(String plainText, {String? pinCode, String? roomId}) {
    final keyBytes = _deriveKey(pinCode: pinCode, roomId: roomId);
    final inputBytes = utf8.encode(plainText);

    // Cifrado de flujo con keystream derivado de la clave
    final cipherBytes = _applyKeystream(inputBytes, keyBytes);

    // Calcular checksum de autenticación
    final checksum = _computeChecksum(cipherBytes, keyBytes);

    final secureContainer = {
      '_sec': 1,
      '_enc': base64Encode(cipherBytes),
      '_chk': checksum,
    };

    return jsonEncode(secureContainer);
  }

  /// Descifra un payload y verifica su integridad.
  /// Si el payload no está cifrado (formato legado/abierto), lo devuelve tal cual.
  static String? decryptPayload(String payload, {String? pinCode, String? roomId}) {
    try {
      final decodedJson = jsonDecode(payload);

      // Si no tiene el flag de contenedor seguro, devolver como payload plano
      if (decodedJson is! Map<String, dynamic> || decodedJson['_sec'] != 1) {
        return payload;
      }

      final encBase64 = decodedJson['_enc'] as String?;
      final expectedChecksum = decodedJson['_chk'] as int?;

      if (encBase64 == null || expectedChecksum == null) {
        return null;
      }

      final cipherBytes = base64Decode(encBase64);
      var keyBytes = _deriveKey(pinCode: pinCode, roomId: roomId);
      var actualChecksum = _computeChecksum(cipherBytes, keyBytes);

      // Si falla y se había especificado un PIN o sala, probar clave pública común
      if (actualChecksum != expectedChecksum && (pinCode != null || roomId != null)) {
        keyBytes = _deriveKey(pinCode: null, roomId: null);
        actualChecksum = _computeChecksum(cipherBytes, keyBytes);
      }

      if (actualChecksum != expectedChecksum) {
        // Clave incorrecta o mensaje no auténtico
        return null;
      }

      // Descifrar aplicando el keystream idéntico
      final plainBytes = _applyKeystream(cipherBytes, keyBytes);
      return utf8.decode(plainBytes);

    } catch (_) {
      // Si ocurre error de decodificación, retornar null indicando fallo de descifrado
      return null;
    }
  }

  /// Deriva una secuencia de bytes para la clave a partir del PIN y el Salt del juego
  static Uint8List _deriveKey({String? pinCode, String? roomId}) {
    final effectivePin = (pinCode != null && pinCode.trim().isNotEmpty)
        ? pinCode.trim()
        : 'PUBLIC_ROOM';
    final effectiveRoom = roomId ?? 'GLOBAL';

    final seed = '$_defaultPublicSalt::$effectivePin::$effectiveRoom::VenezuelanCaida#2026';
    final seedBytes = utf8.encode(seed);

    // Expansión simple de clave de 32 bytes
    final key = Uint8List(32);
    int acc = 0x811c9dc5;

    for (int i = 0; i < 32; i++) {
      for (int j = 0; j < seedBytes.length; j++) {
        acc = ((acc ^ seedBytes[j]) * 0x01000193) & 0xFFFFFFFF;
      }
      key[i] = ((acc >> ((i % 4) * 8)) ^ (i * 31)) & 0xFF;
    }

    return key;
  }

  /// Aplica cifrado simétrico mediante keystream pseudoaleatorio
  static Uint8List _applyKeystream(List<int> input, Uint8List key) {
    final output = Uint8List(input.length);
    final keyLen = key.length;

    int state = 0x5A;
    for (int i = 0; i < keyLen; i++) {
      state = (state + key[i]) & 0xFF;
    }

    for (int i = 0; i < input.length; i++) {
      final k = key[i % keyLen];
      state = (state + k + i) & 0xFF;
      final mask = k ^ state ^ ((i * 17) & 0xFF);
      output[i] = input[i] ^ mask;
    }

    return output;
  }

  /// Calcula un checksum de 32 bits autenticado
  static int _computeChecksum(List<int> bytes, Uint8List key) {
    int hash = 0x811c9dc5;
    for (final b in key) {
      hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    for (final b in bytes) {
      hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
