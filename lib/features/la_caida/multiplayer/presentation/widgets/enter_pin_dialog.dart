import 'package:flutter/material.dart';
import '../../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../../core/theme/app_palette.dart';

/// Modal interactivo para ingresar el Key o PIN de 4 dígitos para unirse a una sala privada
class EnterPinDialog extends StatefulWidget {
  final String roomName;
  final String? expectedPin;
  final ValueChanged<String> onPinSubmitted;

  const EnterPinDialog({
    super.key,
    required this.roomName,
    this.expectedPin,
    required this.onPinSubmitted,
  });

  static Future<String?> show(BuildContext context, {required String roomName, String? expectedPin}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EnterPinDialog(
        roomName: roomName,
        expectedPin: expectedPin,
        onPinSubmitted: (pin) => Navigator.of(context).pop(pin),
      ),
    );
  }

  @override
  State<EnterPinDialog> createState() => _EnterPinDialogState();
}

class _EnterPinDialogState extends State<EnterPinDialog> {
  String _pin = '';
  String? _errorText;

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _errorText = null;
      });
      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorText = null;
      });
    }
  }

  void _submitPin() {
    if (widget.expectedPin != null && widget.expectedPin!.trim() != _pin.trim()) {
      setState(() {
        _errorText = 'Clave incorrecta. Inténtalo de nuevo.';
        _pin = '';
      });
      return;
    }
    widget.onPinSubmitted(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.cartoonBgDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'SALA PRIVADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  TactilePressable(
                    depth: 2.0,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppGradients.redDanger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Introduce el Key de 4 dígitos para entrar a "${widget.roomName}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Casillas de los 4 dígitos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppPalette.cartoonCardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFilled
                            ? const Color(0xFFFBBF24)
                            : AppPalette.cartoonBorder,
                        width: isFilled ? 2.0 : 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isFilled ? '•' : '',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 18),

              // Teclado Numérico
              _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) => _buildKeyBtn(key)).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 64),
              _buildKeyBtn('0'),
              SizedBox(
                width: 64,
                child: IconButton(
                  icon: const Icon(Icons.backspace_rounded, color: Colors.white70, size: 20),
                  onPressed: _onBackspace,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyBtn(String key) {
    return Container(
      width: 64,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: App3dButton(
        onPressed: () => _onKeyPress(key),
        depth: 3,
        borderRadius: 12,
        variant: App3dButtonVariant.dark,
        label: key,
        textStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
