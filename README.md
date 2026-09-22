# CaidaGO

El clásico juego de cartas **La Caída** venezolana, reimaginado como experiencia móvil competitiva con sistema de rangos, economía virtual y progresión.

## Características principales

- **La Caída tradicional**: Baraja española de 40 cartas, modos 1v1 y Parejas (2v2), cantos oficiales (Ronda, Patrulla, Vigía, Registro, Trivilín).
- **Sistema de rangos**: Novato → Bronce → Plata → Oro → Esmeralda → Diamante → Maestro → Gran Maestro → Heroico → Leyenda, cada uno con divisiones numeradas y marcos visuales exclusivos.
- **Progresión por niveles**: 11 niveles base (Novato a Cacique del Trivilín) + niveles de prestigio ilimitados, con XP calculada por calidad de partida.
- **Economía virtual**: Monedas, tickets y diamantes. Mesas VIP con entrada/pozo y comisión del 8 %.
- **Cofres de recompensas**: 4 slots con temporizador o desbloqueo instantáneo por tickets.
- **Potenciadores**: Inventario de boosters activables (máximo 3 simultáneos) con efectos en partida.
- **Retos diarios**: Objetivos con cronómetro en vivo y recompensas rotativas.
- **Logros con niveles**: Bronce, Plata, Oro y Diamante por cada logro del catálogo.
- **Auditoría de partidas**: Historial completo de cada mesa con detalle de cantos, caídas, limpias, puntos excedentes y qué equipo realizó cada acción.
- **Tutorial interactivo**: Tour de 8 etapas que enseña desde la caída básica hasta el Trivilín.
- **IA adaptativa**: Bots con estrategias que priorizan caídas y cantos según contexto de mesa.
- **Feedback háptico**: Vibración en jugadas, caídas, cantos y selecciones.

## Arquitectura

```
lib/
├── core/               # Servicios compartidos (audio, háptico, logger)
│   ├── presentation/   # Widgets reutilizables (App3dButton, TablePlayerBadge)
│   ├── services/       # AudioService, HapticService, DebugLogger
│   └── theme/          # Paleta de colores unificada
├── features/
│   └── la_caida/
│       ├── controllers/    # GameMatchController, MatchPhase
│       ├── domain/         # Modelos puros (PlayingCard, Deck, Player, Canto)
│       ├── economy/        # PlayerSession, UserProgress, RankSystem, Boosters
│       └── presentation/   # Screens (Lobby, Mesa, Splash) y Widgets
└── main.dart
```

## Requisitos

- Flutter SDK 3.12+
- Dart 3.2+
- Android SDK 21+ (para APK)

## Compilar

```bash
# Obtener dependencias
flutter pub get

# Ejecutar tests
flutter test

# Análisis estático
flutter analyze

# Compilar APK release
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

## Licencia

Proyecto privado — todos los derechos reservados.
