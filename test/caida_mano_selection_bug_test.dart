import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/domain/models/mano_draw_session.dart';
import 'package:gme/features/la_caida/economy/vip_tier.dart';
import 'package:gme/features/la_caida/presentation/caida_screen.dart';

void main() {
  group('Sorteo de Mano y Control Anti-Bugs de Selección Única', () {
    test('ManoDrawSession permite que el usuario elija exactamente UNA sola carta', () {
      final session = ManoDrawSession.startNew();
      expect(session.candidates.length, equals(10));
      expect(session.hasUserChosen, isFalse);

      final candidate1 = session.candidates[0];
      final candidate2 = session.candidates[1];

      // Primera selección del usuario (playerIndex 0)
      session.pickCard(candidate1, 0);
      expect(session.hasUserChosen, isTrue);
      expect(candidate1.chosenByPlayerIndex, equals(0));
      expect(candidate1.isRevealed, isTrue);

      // Intento de segunda selección en el mismo candidato (debe ignorarse)
      session.pickCard(candidate1, 0);
      expect(candidate1.chosenByPlayerIndex, equals(0));

      // Intento de selección de una segunda carta diferente por el usuario (debe ignorarse)
      session.pickCard(candidate2, 0);
      expect(candidate2.chosenByPlayerIndex, isNull,
          reason: 'El usuario no puede elegir más de una carta en el sorteo de mano');
      expect(candidate2.isRevealed, isFalse);

      // Los bots (playerIndex >= 1) sí pueden elegir de las disponibles
      session.pickCard(candidate2, 1);
      expect(candidate2.chosenByPlayerIndex, equals(1));
      expect(candidate2.isRevealed, isTrue);
    });

    testWidgets('CaidaScreen en pantalla compacta (340dp) renderiza sin overflow y sin notificación amarilla', (tester) async {
      // Dimensiones de pantalla pequeña de teléfono en horizontal
      tester.view.physicalSize = const Size(800 * 2.0, 340 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CaidaScreen(
            initialPlayers: 2,
            autoStart: true,
            animateDealing: false,
            vipTier: VipTierOffer.tiers[1],
            vipPrizePool: 2000,
            userName: 'Tú',
            botNames: const ['Chupetin'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verificar que no haya overflow
      expect(tester.takeException(), isNull);

      // 2. Verificar que el título CaidaGO y la mesa VIP estén en el app bar
      expect(find.text('CaidaGO'), findsOneWidget);
      expect(find.textContaining('Mesa Club Privado'), findsOneWidget);

      // 3. Verificar que la notificación amarilla invasiva NO exista en la pantalla
      expect(find.textContaining('¡Arrastre! Levantó'), findsNothing);

      // 4. Verificar que ambos jugadores estén presentes en la mesa
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Chupetin'), findsOneWidget);
    });
  });
}
