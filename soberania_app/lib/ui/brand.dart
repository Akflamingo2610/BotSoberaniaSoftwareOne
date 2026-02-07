import 'package:flutter/material.dart';

/// Paleta minimalista baseada na marca (preto/branco).
class Brand {
  static const Color black = Color(0xFF0B0B0B);
  static const Color white = Colors.white;
  static const Color surface = Color(0xFFF6F6F6);
  static const Color border = Color(0xFFE6E6E6);
}

const String _awsLogoAsset = 'assets/images/aws-logo-logo-png-transparent.png';
const String _softwareOneLogoAsset = 'assets/images/logo_da_software.png';

/// Logo da AWS (à direita do header).
/// [size] define altura e largura da caixa para manter proporção igual ao SoftwareOne.
class AwsMark extends StatelessWidget {
  final double size;
  const AwsMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: Image.asset(
        _awsLogoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _AwsMarkFallback(height: size),
      ),
    );
  }
}

class _AwsMarkFallback extends StatelessWidget {
  final double height;
  const _AwsMarkFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Icon(Icons.cloud, size: height, color: Brand.black),
    );
  }
}

/// Logo SoftwareOne (apenas a imagem).
/// [size] define altura; largura proporcional para manter proporção igual à AWS.
class SoftwareOneMark extends StatelessWidget {
  final double size;
  const SoftwareOneMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size,
      child: Image.asset(
        _softwareOneLogoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _SoftwareOneFallback(size: size),
      ),
    );
  }
}

class _SoftwareOneFallback extends StatelessWidget {
  final double size;
  const _SoftwareOneFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Brand.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '1',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Brand.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

PreferredSizeWidget soberaniaAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? leading,
}) {
  return AppBar(
    backgroundColor: Brand.white,
    surfaceTintColor: Brand.white,
    elevation: 0,
    leading: leading,
    automaticallyImplyLeading: leading == null,
    titleSpacing: 16,
    title: Row(
      children: [
        Text(
          'Soberania Digital',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Brand.black,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 20,
          color: Brand.border,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: subtitle != null && subtitle.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Brand.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.black.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.black,
                  ),
                ),
        ),
        const SoftwareOneMark(size: 36),
        const SizedBox(width: 16),
        const AwsMark(size: 36),
      ],
    ),
    iconTheme: const IconThemeData(color: Brand.black),
  );
}
