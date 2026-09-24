import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_palette.dart';
import 'widgets/privacy_policy_dialog.dart';



/// Pantalla "ACERCA DE" y Ajustes del Juego con paleta Cartoon Azul/Púrpura
class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  bool _soundEnabled = true;
  final String _selectedLanguage = 'Español';


  @override
  void initState() {
    super.initState();
    _soundEnabled = !AudioService().isMuted;
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
      AudioService().isMuted = !value;
    });
    if (value) {
      AudioService().playCardFlip();
    }
  }


  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.cartoonBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.cartoonBorder, width: 2),
        ),
        title: const CartoonStrokeText('CALIFICAR CAIDAGO', fontSize: 18),
        content: const Text(
          '¡Gracias por jugar CaidaGO!\nTu apoyo nos ayuda a seguir trayendo nuevas funciones y mejoras criollas.',
          style: TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('LUEGO', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.cartoonYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Gracias por tus 5 estrellas! ⭐⭐⭐⭐⭐'),
                  backgroundColor: AppPalette.cartoonCyan,
                ),
              );
            },
            child: const Text('CALIFICAR ⭐', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.cartoonBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.cartoonBorder, width: 2),
        ),
        title: const CartoonStrokeText('CONTACTO Y SOPORTE', fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Tienes dudas, sugerencias o encontraste un fallo?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF262169),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.cartoonBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_rounded, color: AppPalette.cartoonCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'yoangeleizaga@gmail.com',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.cartoonYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNewsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.cartoonBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.cartoonBorder, width: 2),
        ),
        title: const CartoonStrokeText('NOVEDADES CAIDAGO', fontSize: 18),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 ¡Llegó el Multijugador Local Wi-Fi!',
              style: TextStyle(color: AppPalette.cartoonYellow, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text(
              '• Juega partidas de 2, 3 o 4 jugadores sin consumir datos de internet.\n'
              '• Salas privadas con clave de 4 números y cifrado seguro.\n'
              '• Sustitución y auto-relleno inteligente con bots.\n'
              '• Rediseño cartoon azul y morado para una experiencia más vibrante.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.cartoonYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('¡GENIAL!', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.cartoonBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header estilo cartoon
            _buildHeader(context),

            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    // Versión centrada con líneas decorativas
                    _buildVersionBanner(),

                    const SizedBox(height: 18),

                    // Fila de Controles: SONIDO e IDIOMA
                    _buildControlsRow(),

                    const SizedBox(height: 24),

                    // Sección: INFORMACIÓN
                    _buildSectionTitle(
                      icon: Icons.auto_stories_rounded,
                      title: 'INFORMACIÓN',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoGrid(),

                    const SizedBox(height: 24),

                    // Sección: REDES SOCIALES
                    _buildSectionTitle(
                      icon: Icons.cell_tower_rounded,
                      title: 'REDES SOCIALES',
                    ),
                    const SizedBox(height: 14),
                    _buildSocialRow(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppPalette.cartoonSurface,
        border: Border(
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
        ),
      ),
      child: Row(
        children: [
          CartoonRoundButton(
            onPressed: () => Navigator.of(context).pop(),
            width: 44,
            height: 44,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppPalette.cartoonCardText,
              size: 20,
            ),
          ),
          const Expanded(
            child: CartoonStrokeText(
              'ACERCA DE',
              fontSize: 24,
              textColor: AppPalette.cartoonYellow,
              strokeColor: AppPalette.cartoonCardText,
            ),
          ),
          const SizedBox(width: 44), // Para balancear el botón izquierdo
        ],
      ),
    );
  }

  Widget _buildVersionBanner() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFF5D57C9), thickness: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'VERSIÓN 1.0.0',
            style: TextStyle(
              color: const Color(0xFFD6DBFF).withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFF5D57C9), thickness: 1.5),
        ),
      ],
    );
  }

  Widget _buildControlsRow() {
    return Row(
      children: [
        // Control: SONIDO
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF332D8C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.cartoonBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1B165E),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volume_up_rounded, color: AppPalette.cartoonCyan, size: 20),
                    const SizedBox(width: 6),
                    const CartoonStrokeText(
                      'SONIDO',
                      fontSize: 13,
                      textColor: AppPalette.cartoonCyan,
                      strokeColor: AppPalette.cartoonCardText,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CartoonSwitch(
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Control: IDIOMA
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF332D8C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.cartoonBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1B165E),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.translate_rounded, color: AppPalette.cartoonCyan, size: 20),
                    const SizedBox(width: 6),
                    const CartoonStrokeText(
                      'IDIOMA',
                      fontSize: 13,
                      textColor: AppPalette.cartoonCyan,
                      strokeColor: AppPalette.cartoonCardText,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262169),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedLanguage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppPalette.cartoonCyan, size: 20),
        const SizedBox(width: 8),
        CartoonStrokeText(
          title,
          fontSize: 16,
          textColor: AppPalette.cartoonCyan,
          strokeColor: AppPalette.cartoonCardText,
          strokeWidth: 2.8,
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                icon: Icons.privacy_tip_rounded,
                title: 'PRIVACIDAD',
                onTap: () => PrivacyPolicyDialog.show(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                icon: Icons.star_rounded,
                title: 'CALIFICAR',
                onTap: _showRateAppDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                icon: Icons.description_rounded,
                title: 'TÉRMINOS',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'CaidaGO',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 CaidaGO • Desarrollado por Eizy Systems\nTodos los derechos reservados.',
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                icon: Icons.mail_rounded,
                title: 'CONTACTO',
                onTap: _showContactDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                icon: Icons.newspaper_rounded,
                title: 'NOTICIAS',
                onTap: _showNewsDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                icon: Icons.feedback_rounded,
                title: 'Buzón de Sugerencias',
                subtitle: 'Envíanos tus ideas, mejoras o comentarios',
                onTap: () => FeedbackService.openFeedbackForm(context: context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF332D8C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.cartoonBorder, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1B165E),
                offset: Offset(0, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppPalette.cartoonCyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: Icons.music_note_rounded,
          label: 'TikTok',
          url: 'https://tiktok.com',
        ),
        const SizedBox(width: 14),
        _buildSocialButton(
          icon: Icons.camera_alt_rounded,
          label: 'Instagram',
          url: 'https://instagram.com',
        ),
        const SizedBox(width: 14),
        _buildSocialButton(
          icon: Icons.sports_esports_rounded,
          label: 'Discord',
          url: 'https://discord.com',
        ),
        const SizedBox(width: 14),
        _buildSocialButton(
          icon: Icons.play_arrow_rounded,
          label: 'YouTube',
          url: 'https://youtube.com',
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return CartoonRoundButton(
      width: 50,
      height: 50,
      borderRadius: 14,
      onPressed: () => _launchUrl(url),
      child: Icon(
        icon,
        color: AppPalette.cartoonCardText,
        size: 24,
      ),
    );
  }
}
