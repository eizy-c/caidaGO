import 'dart:async';
import 'package:flutter/material.dart';

enum GameToastType {
  achievement,
  dailyChallenge,
}

class GameToastRequest {
  final GameToastType type;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final int coinReward;
  final int xpReward;

  const GameToastRequest({
    required this.type,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.coinReward,
    required this.xpReward,
  });
}

/// Cola unificada para toasts celebratorios de Logros y Retos Diarios.
/// Se muestran como un banner animado deslizante desde la parte superior.
class GameToastQueue {
  static final GameToastQueue instance = GameToastQueue._();
  GameToastQueue._();

  final List<GameToastRequest> _queue = [];
  bool _isShowing = false;
  OverlayEntry? _currentEntry;

  static void showAchievement(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? description,
    required IconData icon,
    required Color iconColor,
    required int coinReward,
    required int xpReward,
  }) {
    instance.enqueue(
      context,
      GameToastRequest(
        type: GameToastType.achievement,
        title: title,
        subtitle: description ?? subtitle,
        icon: icon,
        iconColor: iconColor,
        coinReward: coinReward,
        xpReward: xpReward,
      ),
    );
  }

  static void showChallenge(
    BuildContext context, {
    required String title,
    required int coinReward,
    required int xpReward,
  }) {
    instance.enqueue(
      context,
      GameToastRequest(
        type: GameToastType.dailyChallenge,
        title: title,
        subtitle: '¡Reto del día completado!',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF84CC16), // Verde lima
        coinReward: coinReward,
        xpReward: xpReward,
      ),
    );
  }

  void enqueue(BuildContext context, GameToastRequest request) {
    _queue.add(request);
    if (!_isShowing) {
      _showNext(context);
    }
  }

  void _showNext(BuildContext context) {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final request = _queue.removeAt(0);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _isShowing = false;
      return;
    }

    _currentEntry = OverlayEntry(
      builder: (ctx) => _ToastBannerWidget(
        request: request,
        onDismissed: () {
          _currentEntry?.remove();
          _currentEntry = null;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              _showNext(context);
            } else {
              _isShowing = false;
            }
          });
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }
}

class _ToastBannerWidget extends StatefulWidget {
  final GameToastRequest request;
  final VoidCallback onDismissed;

  const _ToastBannerWidget({
    required this.request,
    required this.onDismissed,
  });

  @override
  State<_ToastBannerWidget> createState() => _ToastBannerWidgetState();
}

class _ToastBannerWidgetState extends State<_ToastBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Mantener 3.5 segundos visible y luego salir
    _timer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isChallenge = req.type == GameToastType.dailyChallenge;
    final borderColor = isChallenge ? const Color(0xFF84CC16) : req.iconColor;
    final headerLabel = isChallenge ? 'RETO DIARIO COMPLETADO' : '¡LOGRO DESBLOQUEADO!';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icono temático
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E2E2E)),
                      ),
                      child: Icon(req.icon, color: borderColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Título y Recompensas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isChallenge ? Icons.calendar_today_rounded : Icons.military_tech_rounded,
                                size: 11,
                                color: borderColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                headerLabel,
                                style: TextStyle(
                                  color: borderColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            req.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFFFDE047)),
                              const SizedBox(width: 3),
                              Text(
                                '+${req.coinReward}',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.stars_rounded, size: 13, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 3),
                              Text(
                                '+${req.xpReward} XP',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
