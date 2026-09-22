import '../../../../core/models/cards/card_suit.dart';
import '../../../../core/models/cards/spanish_card.dart';

/// Tipo de acción requerida en cada etapa del tutorial guiado.
enum TutorialActionType {
  /// El usuario debe elegir una carta en el sorteo de Mano.
  chooseManoCard,

  /// El usuario lee una explicación pedagógica y pulsa continuar.
  observeStage,

  /// Observación guiada de cantos entre rivales con botón de avance.
  observeCantos,

  /// El usuario debe seleccionar y arrojar una carta específica a la mesa.
  playCard,

  /// El usuario debe pulsar el botón de canto correspondiente.
  callCanto,
}

/// Representa una etapa pedagógica secuencial dentro del tour guiado de novatos.
class TutorialStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String teacherExplanation;
  final TutorialActionType actionType;
  final List<SpanishCard> playerCards;
  final List<SpanishCard> initialTableCards;
  final SpanishCard? targetCard;
  final String? targetCantoName;
  final String feedbackTitle;
  final String feedbackDetail;
  final int pointsAwarded;
  final bool isTrivilinFinale;

  // Globos de diálogo de los 4 jugadores
  final String? userCallout;
  final String? carlosCallout; // Jugador 1 (Oeste / Izquierda)
  final String? mariaCallout;  // Jugador 2 (Norte / Frente)
  final String? pedroCallout;  // Jugador 3 (Este / Derecha)

  // Cantidad de cartas en mano de cada rival
  final int carlosCardsCount;
  final int mariaCardsCount;
  final int pedroCardsCount;

  // Ajustes de puntaje de los rivales en esta etapa
  final int carlosScoreDelta;
  final int mariaScoreDelta;
  final int pedroScoreDelta;

  const TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.teacherExplanation,
    required this.actionType,
    this.playerCards = const [],
    this.initialTableCards = const [],
    this.targetCard,
    this.targetCantoName,
    required this.feedbackTitle,
    required this.feedbackDetail,
    required this.pointsAwarded,
    this.isTrivilinFinale = false,
    this.userCallout,
    this.carlosCallout,
    this.mariaCallout,
    this.pedroCallout,
    this.carlosCardsCount = 3,
    this.mariaCardsCount = 3,
    this.pedroCardsCount = 3,
    this.carlosScoreDelta = 0,
    this.mariaScoreDelta = 0,
    this.pedroScoreDelta = 0,
  });

  /// Lista oficial y secuencial de las 10 etapas pedagógicas de La Caída.
  static List<TutorialStep> get officialSteps => [
        // =====================================================================
        // ETAPA 1: EL SORTEO DE MANO ("¿QUIÉN ES LA MANO?")
        // =====================================================================
        const TutorialStep(
          stepNumber: 1,
          title: 'Etapa 1: El Sorteo de Mano',
          instruction: 'Toca una de las cartas del abanico para sortear quién será "La Mano" de la partida.',
          teacherExplanation:
              'Antes de repartir, cada jugador saca una carta. La carta más alta determina quién es "La Mano", obteniendo el primer turno de juego.',
          actionType: TutorialActionType.chooseManoCard,
          playerCards: [],
          initialTableCards: [],
          feedbackTitle: '¡ERES LA MANO!',
          feedbackDetail:
              '¡Sacaste un Caballo (11)! Tu carta supera al 10, 7 y 4 de tus rivales. Eres "La Mano", sales de primero y el juego avanzará en sentido horario.',
          pointsAwarded: 0,
          carlosCardsCount: 0,
          mariaCardsCount: 0,
          pedroCardsCount: 0,
        ),

        // =====================================================================
        // ETAPA 2: EL REPARTO INICIAL Y LECTURA DE MESA
        // =====================================================================
        const TutorialStep(
          stepNumber: 2,
          title: 'Etapa 2: Reparto y Lectura de Mesa',
          instruction: 'Observa la mesa: Pedro (el repartidor) coloca 4 cartas abiertas y entrega 3 cartas a cada uno.',
          teacherExplanation:
              'Regla oficial: Las 4 cartas iniciales de la mesa no pueden repetir ningún número. Antes de jugar naipes, ¡se declaran los Cantos!',
          actionType: TutorialActionType.observeStage,
          playerCards: [
            SpanishCard(number: 2, suit: CardSuit.oros),
            SpanishCard(number: 5, suit: CardSuit.copas),
            SpanishCard(number: 10, suit: CardSuit.bastos),
          ],
          initialTableCards: [
            SpanishCard(number: 3, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.espadas),
          ],
          feedbackTitle: '¡MESA REPARTIDA!',
          feedbackDetail:
              'Cada jugador tiene 3 cartas secretas. Antes de arrojar naipes a la mesa, se evalúan y cobran los Cantos tradicionales.',
          pointsAwarded: 0,
          pedroCallout: '¡Mesa servida y cartas repartidas!',
        ),

        // =====================================================================
        // ETAPA 3: LA RONDA Y "MATAR CANTOS"
        // =====================================================================
        const TutorialStep(
          stepNumber: 3,
          title: 'Etapa 3: La Ronda y "Matar Cantos"',
          instruction: 'Pedro canta Ronda de 4 (+1 pt), pero María canta Ronda de Sotas (10) (+2 pts).',
          teacherExplanation:
              'Tener dos cartas iguales es una Ronda. Si dos jugadores cantan Ronda, la de mayor número ANULA (mata) a la inferior y solo cobra la mayor.',
          actionType: TutorialActionType.observeCantos,
          playerCards: [
            SpanishCard(number: 2, suit: CardSuit.oros),
            SpanishCard(number: 5, suit: CardSuit.copas),
            SpanishCard(number: 10, suit: CardSuit.bastos),
          ],
          initialTableCards: [
            SpanishCard(number: 3, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.espadas),
          ],
          pedroCallout: '¡Ronda de 4! (+1 pt)',
          mariaCallout: '¡Te la mato! ¡Ronda de Sotas! (+2 pts)',
          mariaScoreDelta: 2,
          feedbackTitle: '¡RONDA MATADA (+2 PTS PARA MARÍA)!',
          feedbackDetail:
              '¡Regla de oro! Las figuras valen más: cartas del 1 al 7 (+1 pt), Sota 10 (+2 pts), Caballo 11 (+3 pts) y Rey 12 (+4 pts).',
          pointsAwarded: 0,
        ),

        // =====================================================================
        // ETAPA 4: LA PATRULLA (ESCALERA CONSECUTIVA)
        // =====================================================================
        const TutorialStep(
          stepNumber: 4,
          title: 'Etapa 4: La Patrulla Tradicional',
          instruction: 'Carlos canta "¡Patrulla!" con una escalera de 4, 5 y 6 (+6 pts).',
          teacherExplanation:
              'Tres cartas consecutivas forman la Patrulla tradicional. Otorga +6 puntos directos y por jerarquía anula a cualquier Ronda.',
          actionType: TutorialActionType.observeCantos,
          playerCards: [
            SpanishCard(number: 2, suit: CardSuit.oros),
            SpanishCard(number: 5, suit: CardSuit.copas),
            SpanishCard(number: 10, suit: CardSuit.bastos),
          ],
          initialTableCards: [
            SpanishCard(number: 3, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.espadas),
          ],
          carlosCallout: '¡PATRULLA! (4, 5 y 6) (+6 pts)',
          carlosScoreDelta: 6,
          feedbackTitle: '¡PATRULLA COBRADA (+6 PTS)!',
          feedbackDetail:
              '¡Poderosa escalera! La Patrulla supera a todas las Rondas sin importar si eran de Reyes.',
          pointsAwarded: 0,
        ),

        // =====================================================================
        // ETAPA 5: EL VIGÍA (INTERACTIVO PARA EL USUARIO)
        // =====================================================================
        const TutorialStep(
          stepNumber: 5,
          title: 'Etapa 5: El Canto de Vigía',
          instruction: 'Tienes dos 7 y un 6 (adyacente). ¡Toca el botón pulsante para cantar "¡VIGÍA!" (+7 pts)!',
          teacherExplanation:
              'Dos cartas iguales más una consecutiva inmediata (ej: 7-7-6 o 10-10-11) forman el Vigía (+7 pts), superando a la Patrulla y a la Ronda.',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 7, suit: CardSuit.copas),
            SpanishCard(number: 7, suit: CardSuit.bastos),
            SpanishCard(number: 6, suit: CardSuit.oros),
          ],
          initialTableCards: [
            SpanishCard(number: 3, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.espadas),
          ],
          targetCantoName: 'VIGÍA',
          userCallout: '¡VIGÍA! (+7 pts)',
          feedbackTitle: '¡VIGÍA CANTADO (+7 PTS)!',
          feedbackDetail:
              '¡Gran jugada! Tu Vigía de 7 con 6 otorga 7 puntos y se impone sobre la Patrulla y las Rondas anteriores.',
          pointsAwarded: 7,
        ),

        // =====================================================================
        // ETAPA 6: EL REGISTRO (CANTO DE GALA)
        // =====================================================================
        const TutorialStep(
          stepNumber: 6,
          title: 'Etapa 6: El Registro de Gala',
          instruction: 'Conoce El Registro: As (1), Caballo (11) y Rey (12) juntos en mano (+8 pts).',
          teacherExplanation:
              'El Registro es la combinación noble más codiciada de la baraja. Suma +8 puntos y es la segunda jugada más alta antes del Trivilín.',
          actionType: TutorialActionType.observeStage,
          playerCards: [
            SpanishCard(number: 1, suit: CardSuit.espadas),
            SpanishCard(number: 11, suit: CardSuit.copas),
            SpanishCard(number: 12, suit: CardSuit.oros),
          ],
          initialTableCards: [
            SpanishCard(number: 3, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.espadas),
          ],
          feedbackTitle: '¡EL REGISTRO NOBLE (+8 PTS)!',
          feedbackDetail:
              '¡As, Caballo y Rey [1, 11, 12]! Solo el mítico Trivilín de tres cartas iguales puede superar a un Registro.',
          pointsAwarded: 0,
        ),

        // =====================================================================
        // ETAPA 7: LA CAÍDA DIRECTA (MECÁNICA PRINCIPAL)
        // =====================================================================
        const TutorialStep(
          stepNumber: 7,
          title: 'Etapa 7: La Caída Directa',
          instruction: 'Carlos acaba de jugar un 6 de Espadas. Toca tu 6 de Copas para hacerle "CAÍDA".',
          teacherExplanation:
              'Si juegas una carta del mismo número que acaba de tirar el jugador previo, haces CAÍDA, sumas los puntos de esa carta y te llevas los naipes a tu pozo.',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 6, suit: CardSuit.copas),
            SpanishCard(number: 2, suit: CardSuit.bastos),
            SpanishCard(number: 11, suit: CardSuit.oros),
          ],
          initialTableCards: [
            SpanishCard(number: 6, suit: CardSuit.espadas),
          ],
          targetCard: SpanishCard(number: 6, suit: CardSuit.copas),
          carlosCallout: 'Tiro mi 6 de Espadas...',
          userCallout: '¡Caída!',
          feedbackTitle: '¡CAÍDA! (+1 PT)',
          feedbackDetail:
              '¡Golpe certero! Al empatar la carta del jugador previo cobras sus puntos (1 al 7 = +1 pt, Sota = +2, Caballo = +3, Rey = +4) y te adueñas de ambas cartas.',
          pointsAwarded: 1,
        ),

        // =====================================================================
        // ETAPA 8: ARRASTRE Y SEGUIDILLA
        // =====================================================================
        const TutorialStep(
          stepNumber: 8,
          title: 'Etapa 8: Arrastre y Seguidilla',
          instruction: 'En mesa hay 7, 10 y 11. Tira tu 7 de Espadas para capturar el 7 y arrastrar en seguidilla el 10 y el 11.',
          teacherExplanation:
              'Al empatar un número de la mesa, también levantas de corrido todas las cartas consecutivas superiores inmediatas. ¡En la baraja de 40 del 7 se salta a la Sota 10!',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 7, suit: CardSuit.espadas),
            SpanishCard(number: 4, suit: CardSuit.oros),
          ],
          initialTableCards: [
            SpanishCard(number: 7, suit: CardSuit.bastos),
            SpanishCard(number: 10, suit: CardSuit.oros),
            SpanishCard(number: 11, suit: CardSuit.copas),
          ],
          targetCard: SpanishCard(number: 7, suit: CardSuit.espadas),
          userCallout: '¡Arrastre!',
          feedbackTitle: '¡ARRASTRE EN SEGUIDILLA!',
          feedbackDetail:
              '¡Levantaste 3 cartas de una vez! El arrastre consecutivo es vital para acumular cartas en tu pozo de volumen (más de 20 cartas dan puntos al final).',
          pointsAwarded: 1,
        ),

        // =====================================================================
        // ETAPA 9: MESA LIMPIA
        // =====================================================================
        const TutorialStep(
          stepNumber: 9,
          title: 'Etapa 9: Mesa Limpia',
          instruction: 'Queda solo un Rey (12) en la mesa. Juega tu Rey de Copas para capturarlo y dejar el tapete vacío.',
          teacherExplanation:
              'Capturar la última carta y dejar la mesa completamente vacía otorga +4 puntos de Mesa Limpia (+0 pts si el mazo ya está agotado en la última mano).',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 12, suit: CardSuit.copas),
          ],
          initialTableCards: [
            SpanishCard(number: 12, suit: CardSuit.oros),
          ],
          targetCard: SpanishCard(number: 12, suit: CardSuit.copas),
          userCallout: '¡Mesa Limpia!',
          feedbackTitle: '¡MESA LIMPIA (+4 PTS)!',
          feedbackDetail:
              '¡Tapete limpio como un espejo! Sumas +4 puntos directos. Recuerda mantener la mesa despejada para asfixiar las opciones de tus rivales.',
          pointsAwarded: 4,
        ),

        // =====================================================================
        // ETAPA 10: ¡TRIVILÍN Y VICTORIA INMEDIATA!
        // =====================================================================
        const TutorialStep(
          stepNumber: 10,
          title: 'Etapa 10: ¡Trivilín y Nocaut!',
          instruction: 'Los rivales cantaron alto, ¡pero tú tienes 3 Caballos iguales! Toca el botón de "¡TRIVILÍN!" para ganar de inmediato.',
          teacherExplanation:
              'Tres cartas del mismo número forman el legendario Trivilín. Otorga 24 puntos al instante y termina la partida con KO fulminante.',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 11, suit: CardSuit.oros),
            SpanishCard(number: 11, suit: CardSuit.copas),
            SpanishCard(number: 11, suit: CardSuit.espadas),
          ],
          initialTableCards: [
            SpanishCard(number: 1, suit: CardSuit.bastos),
            SpanishCard(number: 4, suit: CardSuit.copas),
          ],
          targetCantoName: '¡TRIVILÍN!',
          carlosCallout: '¡Tengo Patrulla (+6 pts)!',
          pedroCallout: '¡Yo tengo Registro (+8 pts)!',
          userCallout: '¡¡¡TRIVILÍN GANAMOS TODO!!!',
          feedbackTitle: '¡¡TRIVILÍN! ¡VICTORIA POR NOCAUT!!',
          feedbackDetail:
              '¡TRES CARTAS DEL MISMO NÚMERO SON TRIVILÍN! Otorga 24 puntos inmediatos y gana la partida por knock-out absoluto sin importar el marcador previo.',
          pointsAwarded: 24,
          isTrivilinFinale: true,
        ),
      ];
}
