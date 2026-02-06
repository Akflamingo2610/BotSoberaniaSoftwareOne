import 'package:flutter/material.dart';

/// Paleta minimalista baseada na marca (preto/branco).
class Brand {
  static const Color black = Color(0xFF0B0B0B);
  static const Color white = Colors.white;
  static const Color surface = Color(0xFFF6F6F6);
  static const Color border = Color(0xFFE6E6E6);
}

/// Logo oficial AWS: "aws" em minúsculo + traço laranja (fundo claro).
/// Para usar sua própria imagem: coloque em assets/images/aws_logo.png,
/// declare em pubspec.yaml e troque por Image.asset('assets/images/aws_logo.png').
const String _awsLogoUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Amazon_Web_Services_Logo.svg/240px-Amazon_Web_Services_Logo.svg.png';

/// Logo da AWS (wordmark "aws" + swoosh laranja) para uso no header.
class AwsMark extends StatelessWidget {
  final double height;
  const AwsMark({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _awsLogoUrl,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _AwsMarkFallback(height: height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          width: height * 2.2,
          child: Center(
            child: SizedBox(
              width: height * 0.5,
              height: height * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Brand.black,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fallback quando a imagem do logo não carrega (rede/offline).
class _AwsMarkFallback extends StatelessWidget {
  final double height;

  const _AwsMarkFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        'AWS',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Brand.black,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

/// Logo "SoftwareOne" desenhado em Flutter (sem precisar de asset).
class SoftwareOneMark extends StatelessWidget {
  final double size;
  const SoftwareOneMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Brand.black,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'one',
            style: textTheme.labelLarge?.copyWith(
              color: Brand.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Soberania',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Brand.black,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

PreferredSizeWidget soberaniaAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return AppBar(
    backgroundColor: Brand.white,
    surfaceTintColor: Brand.white,
    elevation: 0,
    titleSpacing: 16,
    title: Row(
      children: [
        const AwsMark(height: 26),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 20,
          color: Brand.border,
        ),
        const SizedBox(width: 16),
        const SoftwareOneMark(size: 24),
        const SizedBox(width: 12),
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
      ],
    ),
    iconTheme: const IconThemeData(color: Brand.black),
  );
}
