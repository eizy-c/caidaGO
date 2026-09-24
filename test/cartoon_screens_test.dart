import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/multiplayer/presentation/multiplayer_hub_screen.dart';
import 'package:gme/features/la_caida/presentation/about_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerSession.setShared(PlayerSession.createDefault());
  });

  group('MultiplayerHubScreen - UI Cartoon y Distribución', () {
    testWidgets('Renderiza título SALAS, tabs de filtro y botón inferior CREAR SALA', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultiplayerHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Cabecera
      expect(find.text('SALAS'), findsWidgets);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Pestañas (CartoonStrokeText tiene capa de borde y capa de relleno)
      expect(find.text('TODAS'), findsWidgets);
      expect(find.text('SIN CONTRASEÑA'), findsWidgets);

      // Botón CREAR SALA
      expect(find.text('CREAR SALA'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('Tocar CREAR SALA abre el modal de configuración con opciones criollas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultiplayerHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal de creación
      await tester.tap(find.text('CREAR SALA'));
      await tester.pumpAndSettle();

      expect(find.text('CANTIDAD DE JUGADORES'), findsOneWidget);
      expect(find.text('1 vs 1'), findsOneWidget);
      expect(find.text('Trío'), findsOneWidget);
      expect(find.text('Mesa 4'), findsOneWidget);
      expect(find.text('ABRIR SALA (SIN INTERNET)'), findsWidgets);

    });

    testWidgets('Tocar botón de búsqueda abre diálogo de entrada rápida con PIN', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultiplayerHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.text('BUSCAR / UNIRSE'), findsWidgets);
      expect(find.text('ENTRAR'), findsOneWidget);
    });
  });

  group('AboutSettingsScreen - UI Cartoon y Distribución', () {
    testWidgets('Renderiza ACERCA DE, controles de sonido/idioma, información y redes sociales', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACERCA DE'), findsWidgets);
      expect(find.text('VERSIÓN 1.0.0'), findsOneWidget);
      expect(find.text('SONIDO'), findsWidgets);
      expect(find.text('IDIOMA'), findsWidgets);
      expect(find.text('Español'), findsOneWidget);

      // Sección Información
      expect(find.text('INFORMACIÓN'), findsWidgets);
      expect(find.text('PRIVACIDAD'), findsOneWidget);
      expect(find.text('CALIFICAR'), findsOneWidget);
      expect(find.text('TÉRMINOS'), findsOneWidget);
      expect(find.text('CONTACTO'), findsOneWidget);
      expect(find.text('NOTICIAS'), findsOneWidget);
      expect(find.text('Buzón de Sugerencias'), findsOneWidget);

      // Redes sociales
      expect(find.text('REDES SOCIALES'), findsWidgets);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget); // TikTok
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget); // Instagram
      expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget); // Discord
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget); // YouTube
    });
  });
}
