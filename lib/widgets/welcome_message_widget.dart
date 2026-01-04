import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

/// Widget que muestra el mensaje de bienvenida personalizado de la organización
class WelcomeMessageWidget extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const WelcomeMessageWidget({
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        // Obtener branding actual
        final branding = themeProvider.branding;
        if (branding == null) {
          return const SizedBox.shrink();
        }

        // Obtener mensaje en el idioma actual
        final currentLanguage = localeProvider.locale.languageCode;
        final message = branding.welcomeMessage[currentLanguage] ?? 
                       branding.welcomeMessage['es'] ?? 
                       'Bienvenido';

        return Text(
          message,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Widget que muestra el nombre de la organización
class OrganizationNameWidget extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const OrganizationNameWidget({
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final branding = themeProvider.branding;
        if (branding == null) {
          return const SizedBox.shrink();
        }

        return Text(
          branding.organizationName,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Widget que muestra el logo de la organización
class OrganizationLogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OrganizationLogoWidget({
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final branding = themeProvider.branding;
        final logoUrl = branding?.logoUrl;

        if (logoUrl == null) {
          return placeholder ?? 
              Icon(
                Icons.business,
                size: height ?? 48,
                color: Colors.grey,
              );
        }

        return Image.network(
          logoUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return placeholder ?? 
                Icon(
                  Icons.broken_image,
                  size: height ?? 48,
                  color: Colors.grey,
                );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card de bienvenida personalizado para usar en dashboards
class WelcomeCard extends StatelessWidget {
  final String? userName;
  final VoidCallback? onTap;

  const WelcomeCard({
    Key? key,
    this.userName,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const OrganizationLogoWidget(
                    height: 48,
                    width: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userName != null)
                          Text(
                            '¡Hola, $userName!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        const OrganizationNameWidget(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const WelcomeMessageWidget(
                style: TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}