import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/player_session.dart';
import 'avatar_view.dart';
import 'user_frame_view.dart';

/// Modal moderno para editar el perfil del jugador y seleccionar entre los avatares
/// de Héroes disponibles, unificado con la paleta oficial de CaidaGO (AppPalette).
class ProfileOptionsDialog extends StatefulWidget {
  const ProfileOptionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ProfileOptionsDialog(),
    );
  }

  @override
  State<ProfileOptionsDialog> createState() => _ProfileOptionsDialogState();
}

class _ProfileOptionsDialogState extends State<ProfileOptionsDialog> {
  final _profileService = UserProfileService();
  late TextEditingController _nameController;
  late int _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profileService.name);
    _selectedAvatarId = _profileService.avatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final finalName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Jugador';
    _profileService.updateProfile(
      name: finalName,
      avatarId: _selectedAvatarId,
    );
    PlayerSession.shared.updateProfile(
      name: finalName,
      avatarIndex: _selectedAvatarId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final heroes = AvatarPreset.heroesPresets;
    final currentHero = AvatarPreset.getById(_selectedAvatarId);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 580),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF262626),
                AppPalette.darkSlate,
                Color(0xFF171717),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppPalette.cyan.withValues(alpha: 0.65),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppPalette.cyan.withValues(alpha: 0.08),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Cabecera Unificada con Icono y Botón Cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppPalette.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppPalette.cyan.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.manage_accounts_rounded,
                              color: AppPalette.cyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'OPCIONES DEL PERFIL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF333333), height: 1, thickness: 1),

              // 2. Contenido Scrolleable (Previsualización, Nombre y Héroes)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    children: [
                      // Previsualización del Avatar con su Marco Activo
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            UserFrameView(
                              avatarIndex: _selectedAvatarId,
                              frameId: PlayerSession.shared.selectedFrameId,
                              level: PlayerSession.shared.level,
                              size: 86,
                              showLevelBadge: true,
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppPalette.cyan,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppPalette.darkSlate,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppPalette.cyan.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: AppPalette.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Nombre del héroe seleccionado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppPalette.cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppPalette.cyan.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          currentHero.name,
                          style: const TextStyle(
                            color: AppPalette.cyan,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Campo de texto para el Nombre del Jugador
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppPalette.sand.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          maxLength: 14,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tu nombre',
                            hintStyle: TextStyle(
                              color: AppPalette.sand.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_rounded,
                              size: 18,
                              color: AppPalette.cyan,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Encabezado de la Galería de Héroes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 15,
                                color: AppPalette.cyan,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SELECCIONA TU HÉROE',
                                style: TextStyle(
                                  color: AppPalette.sand,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppPalette.olive.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppPalette.olive.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${heroes.length} Héroes',
                              style: const TextStyle(
                                color: AppPalette.sand,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Galería de Héroes (Solo avatares de imagen)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2E2E2E),
                            width: 1,
                          ),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: heroes.map((hero) {
                            final isSel = hero.id == _selectedAvatarId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAvatarId = hero.id;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSel
                                                ? AppPalette.cyan
                                                : Colors.white.withValues(alpha: 0.2),
                                            width: isSel ? 2.5 : 1.2,
                                          ),
                                          boxShadow: isSel
                                              ? [
                                                  BoxShadow(
                                                    color: AppPalette.cyan.withValues(alpha: 0.45),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            hero.imagePath,
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: hero.bgColor,
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isSel)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppPalette.cyan,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 11,
                                              color: AppPalette.darkSlate,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      hero.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSel ? AppPalette.cyan : Colors.white60,
                                        fontSize: 10,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: Color(0xFF333333), height: 1, thickness: 1),

              // 3. Botones Inferiores de Acción (Cancelar / Guardar 3D)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: App3dButton(
                        onPressed: () => Navigator.of(context).pop(),
                        variant: App3dButtonVariant.dark,
                        height: 42,
                        depth: 4,
                        borderRadius: 12,
                        label: 'CANCELAR',
                        textStyle: const TextStyle(
                          color: AppPalette.sand,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: App3dButton(
                        onPressed: _saveAndClose,
                        variant: App3dButtonVariant.cyan,
                        height: 42,
                        depth: 4,
                        borderRadius: 12,
                        label: 'GUARDAR',
                        icon: Icons.check_circle_rounded,
                        textStyle: const TextStyle(
                          color: AppPalette.darkSlate,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
