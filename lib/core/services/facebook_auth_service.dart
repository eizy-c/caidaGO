import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Modelo con los datos de un usuario autenticado vía Facebook.
class FacebookUserData {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;

  const FacebookUserData({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  factory FacebookUserData.fromMap(Map<String, dynamic> map) {
    String? photoUrl;
    final picture = map['picture'] as Map<String, dynamic>?;
    if (picture != null) {
      final data = picture['data'] as Map<String, dynamic>?;
      if (data != null) {
        photoUrl = data['url'] as String?;
      }
    }

    return FacebookUserData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Jugador',
      email: map['email'] as String?,
      avatarUrl: photoUrl,
    );
  }
}

/// Resultado de una operación de inicio de sesión con Facebook.
class FacebookAuthResponse {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;
  final FacebookUserData? userData;

  const FacebookAuthResponse({
    required this.isSuccess,
    this.isCancelled = false,
    this.errorMessage,
    this.userData,
  });

  factory FacebookAuthResponse.success(FacebookUserData user) =>
      FacebookAuthResponse(isSuccess: true, userData: user);

  factory FacebookAuthResponse.cancelled() =>
      const FacebookAuthResponse(isSuccess: false, isCancelled: true);

  factory FacebookAuthResponse.failed(String message) =>
      FacebookAuthResponse(isSuccess: false, errorMessage: message);
}

/// Servicio centralizado de autenticación con Facebook para CaidaGO.
class FacebookAuthService {
  static final FacebookAuthService instance = FacebookAuthService._internal();
  FacebookAuthService._internal();

  /// Comprueba si hay una sesión activa de Facebook guardada
  Future<bool> get isLoggedIn async {
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Inicia el flujo de autenticación con Facebook (Nativo o Web seguro)
  Future<FacebookAuthResponse> login() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final userDataMap = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200).height(200)",
        );
        final user = FacebookUserData.fromMap(userDataMap);
        return FacebookAuthResponse.success(user);
      } else if (result.status == LoginStatus.cancelled) {
        return FacebookAuthResponse.cancelled();
      } else {
        return FacebookAuthResponse.failed(
          result.message ?? 'No se pudo iniciar sesión con Facebook.',
        );
      }
    } catch (e) {
      debugPrint('[FacebookAuthService] Error durante el login: $e');
      return FacebookAuthResponse.failed(
        'Error de conexión con Facebook: $e',
      );
    }
  }

  /// Cierra la sesión activa en el SDK de Facebook
  Future<void> logout() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('[FacebookAuthService] Error durante el logout: $e');
    }
  }

  /// Obtiene los datos del perfil si ya hay una sesión activa
  Future<FacebookUserData?> fetchCurrentProfile() async {
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken == null) return null;
      final data = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture.width(200).height(200)",
      );
      return FacebookUserData.fromMap(data);
    } catch (_) {
      return null;
    }
  }
}
