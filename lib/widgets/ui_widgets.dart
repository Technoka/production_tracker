import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/ui_constants.dart';

// =============================================================================
// UI WIDGETS CENTRALIZADOS — lib/widgets/ui_widgets.dart
//
// Widgets y diálogos reutilizables para mantener coherencia visual en toda la app.
//
// ── DIÁLOGOS (via AppDialogs.*) ───────────────────────────────────────────────
//   AppDialogs.showPhaseMoveConfirmation(...)   → PhaseMoveResult
//   AppDialogs.showUnsavedChanges(...)          → bool
//   AppDialogs.showDeleteSimple(...)            → bool
//   AppDialogs.showDeletePermanently(...)          → bool
//   AppDialogs.showConfirmation(...)            → bool
//   AppDialogs.showPermissionDenied(...)        → void
//   AppDialogs.showDateRangePicker(...)         → DateTimeRange?
//
// ── WIDGETS ───────────────────────────────────────────────────────────────────
//   UnsavedChangesGuard     : PopScope que intercepta el back si hay cambios
//   LoadingOverlay          : Bloqueo de pantalla durante operaciones async
//   EmptyStateWidget        : Placeholder para listas y estados vacíos
//
// ── NOTIFICACIONES (via AppSnackBars.*) ───────────────────────────────────────
//   AppSnackBars.success(context, message)
//   AppSnackBars.error(context, message)
//   AppSnackBars.info(context, message)
//   AppSnackBars.warning(context, message)
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE RESULTADO
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del diálogo de cambio de fase.
class PhaseMoveResult {
  final bool confirmed;
  final String? notes;
  const PhaseMoveResult({required this.confirmed, this.notes});
}

// =============================================================================
// 1. DIÁLOGO DE CONFIRMACIÓN DE CAMBIO DE FASE
// =============================================================================

/// Diálogo de confirmación para mover un producto a otra fase.
/// Visualmente idéntico al diálogo original del kanban board widget,
/// con campo de notas opcional añadido.
///
/// Uso recomendado via [AppDialogs.showPhaseMoveConfirmation].
class PhaseMoveConfirmationDialog extends StatefulWidget {
  final String productName;
  final String batchNumber;
  final String productReference;
  final String fromPhaseName;
  final String toPhaseName;
  final bool isForward;

  const PhaseMoveConfirmationDialog({
    super.key,
    required this.productName,
    required this.batchNumber,
    required this.productReference,
    required this.fromPhaseName,
    required this.toPhaseName,
    required this.isForward,
  });

  @override
  State<PhaseMoveConfirmationDialog> createState() =>
      _PhaseMoveConfirmationDialogState();
}

class _PhaseMoveConfirmationDialogState
    extends State<PhaseMoveConfirmationDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = widget.isForward ? Colors.green : Colors.orange;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isForward ? Icons.arrow_forward : Icons.arrow_back,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isForward
                  ? l10n.moveProductForward
                  : l10n.moveProductBackward,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.batchLabel} ${widget.batchNumber}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            '${l10n.skuLabel} ${widget.productReference}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.from}: ${widget.fromPhaseName}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.to}: ${widget.toPhaseName}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          // Banner de advertencia solo en retroceso — igual que el original
          if (!widget.isForward) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.moveWarningPart1} ${widget.toPhaseName}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Campo de notas opcional — añadido sobre el diseño original
          // const SizedBox(height: 16),
          // TextField(
          //   controller: _notesController,
          //   maxLines: 3,
          //   textCapitalization: TextCapitalization.sentences,
          //   decoration: InputDecoration(
          //     labelText: l10n.notes,
          //     border: const OutlineInputBorder(),
          //     hintText: l10n.notesHint,
          //   ),
          // ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(const PhaseMoveResult(confirmed: false)),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final notes = _notesController.text.trim();
            Navigator.of(context).pop(PhaseMoveResult(
              confirmed: true,
              notes: notes.isEmpty ? null : notes,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
          ),
          child: Text(widget.isForward ? l10n.moveForward : l10n.moveBackward),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. GUARDIA DE CAMBIOS NO GUARDADOS
// =============================================================================

/// Envuelve un formulario y muestra un diálogo si el usuario intenta salir
/// con cambios sin guardar. Usa [PopScope] (API moderna, no WillPopScope).
///
/// Uso:
/// ```dart
/// UnsavedChangesGuard(
///   hasChanges: _hasUnsavedChanges,
///   child: YourFormWidget(),
/// )
/// ```
/// O para control manual:
/// ```dart
/// final ok = await AppDialogs.showUnsavedChanges(context);
/// if (ok) Navigator.pop(context);
/// ```
class UnsavedChangesGuard extends StatelessWidget {
  final bool hasChanges;
  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await AppDialogs.showUnsavedChanges(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

// =============================================================================
// 3. LOADING OVERLAY
// =============================================================================

/// Bloquea la pantalla con un indicador de carga semitransparente.
/// Evita que el usuario interactúe mientras se ejecuta una operación async.
///
/// Uso:
/// ```dart
/// LoadingOverlay(
///   isLoading: _isLoading,
///   message: 'Guardando...', // opcional
///   child: YourScreenContent(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: barrierColor ?? Colors.black.withOpacity(0.35),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          if (message != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 4. EMPTY STATE WIDGET
// =============================================================================

/// Placeholder unificado para listas vacías y estados sin datos.
///
/// Uso:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inventory_2_outlined,
///   title: 'Sin productos',
///   subtitle: 'Añade un producto para empezar', // opcional
///   actionLabel: 'Añadir',                       // opcional
///   onAction: () => _navigateToAdd(),             // opcional
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  final double? iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize ?? 64,
              color: theme.colorScheme.onSurface.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 5. APP SNACK BARS
// =============================================================================

/// Clase estática para mostrar SnackBars con estilo visual consistente.
///
/// Uso:
/// ```dart
/// AppSnackBars.success(context, 'Producto guardado');
/// AppSnackBars.error(context, 'Error al guardar: $e');
/// AppSnackBars.info(context, 'Sincronizando datos...');
/// AppSnackBars.warning(context, 'Sin conexión a internet');
/// ```
class AppSnackBars {
  AppSnackBars._();

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: Colors.green.shade700,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: Theme.of(context).colorScheme.error,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: Theme.of(context).colorScheme.primary,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: Colors.orange.shade700,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration ?? const Duration(seconds: 3),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// =============================================================================
// 6. APP DIALOGS — Acceso centralizado a todos los diálogos
// =============================================================================

class AppDialogs {
  AppDialogs._();

  // ── 6.1 Cambio de fase ──────────────────────────────────────────────────────

  /// Confirmación de cambio de fase. Visualmente idéntico al diálogo original
  /// del kanban board, con campo de notas opcional añadido.
  /// Devuelve [PhaseMoveResult] con `confirmed` y `notes` (nullable).
  static Future<PhaseMoveResult> showPhaseMoveConfirmation({
    required BuildContext context,
    required String productName,
    required String batchNumber,
    required String productReference,
    required String fromPhaseName,
    required String toPhaseName,
    required bool isForward,
  }) async {
    final result = await showDialog<PhaseMoveResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PhaseMoveConfirmationDialog(
        productName: productName,
        batchNumber: batchNumber,
        productReference: productReference,
        fromPhaseName: fromPhaseName,
        toPhaseName: toPhaseName,
        isForward: isForward,
      ),
    );
    return result ?? const PhaseMoveResult(confirmed: false);
  }

  // ── 6.2 Cambios no guardados ────────────────────────────────────────────────

  /// Popup de salida sin guardar. Ancho máximo 300px.
  /// Devuelve `true` si el usuario confirma que quiere salir.
  static Future<bool> showUnsavedChanges(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: UIConstants.POP_UPS_MAX_WIDTH),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.unsavedChangesTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.unsavedChangesMessage,
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.keepEditing),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error),
                child: Text(l10n.discardChanges),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  // ── 6.3 Eliminación simple ──────────────────────────────────────────────────

  /// Diálogo de eliminación estándar con un solo botón de confirmación.
  /// Usar para acciones recuperables o de bajo riesgo.
  ///
  /// Ejemplo:
  /// ```dart
  /// final ok = await AppDialogs.showDeleteSimple(
  ///   context: context,
  ///   itemName: product.productName,
  ///   itemType: 'producto',
  /// );
  /// ```
  static Future<bool> showDeleteSimple({
    required BuildContext context,
    required String itemName,
    String? itemType,
    String? customMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final typeLine = itemType != null ? ' $itemType' : '';

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: UIConstants.POP_UPS_MAX_WIDTH),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            title: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    color: theme.colorScheme.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.delete,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Text(
              customMessage ??
                  '${l10n.deleteSimpleConfirmPrefix}$typeLine "${itemName}"?\n\n${l10n.deleteSimpleWarning}',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  // ── 6.4 Eliminación crítica (confirmar nombre) ──────────────────────────────

  /// Diálogo de eliminación irreversible. El usuario debe escribir el nombre
  /// exacto del elemento para desbloquear el botón de confirmar.
  /// Usar para borrados permanentes (organizaciones, lotes completos, etc).
  ///
  /// Ejemplo:
  /// ```dart
  /// final ok = await AppDialogs.showDeletePermanently(
  ///   context: context,
  ///   itemName: organization.name,
  ///   itemType: 'organización',
  ///   warningDetail: 'Se eliminarán todos los miembros, lotes y productos.',
  /// );
  /// ```
  static Future<bool> showDeletePermanently({
    required BuildContext context,
    required String itemName,
    String? itemType,
    String? warningDetail,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DeletePermanentlyDialog(
        itemName: itemName,
        itemType: itemType,
        warningDetail: warningDetail,
      ),
    );
    return result ?? false;
  }

  // ── 6.5 Permiso denegado ────────────────────────────────────────────────────

  /// Informa al usuario de que no tiene permisos para realizar la acción.
  ///
  /// Ejemplo:
  /// ```dart
  /// await AppDialogs.showPermissionDenied(
  ///   context: context,
  ///   action: 'editar este producto',
  /// );
  /// ```
  static Future<void> showPermissionDenied({
    required BuildContext context,
    String? action,
    bool showContactAdmin = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: UIConstants.POP_UPS_MAX_WIDTH),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            title: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: theme.colorScheme.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.permissionDeniedTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action != null
                      ? '${l10n.permissionDeniedActionPrefix} $action.'
                      : l10n.permissionDeniedGeneric,
                  style: theme.textTheme.bodyMedium,
                ),
                if (showContactAdmin) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.permissionDeniedContactAdmin,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.understood),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 6.6 Selector de rango de fechas ────────────────────────────────────────

  /// Abre el selector de rango de fechas nativo de Flutter con estilo
  /// consistente. Devuelve [DateTimeRange] o `null` si el usuario cancela.
  ///
  /// Ejemplo:
  /// ```dart
  /// final range = await AppDialogs.showDateRangePicker(
  ///   context: context,
  ///   initialRange: _activeFilter,
  /// );
  /// if (range != null) setState(() => _activeFilter = range);
  /// ```
  static Future<DateTimeRange?> showCustomDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? now,
      initialDateRange: initialRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── 6.7 Confirmación genérica ───────────────────────────────────────────────

  /// Diálogo de confirmación simple para cualquier acción que no tenga
  /// un diálogo específico.
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
    IconData? icon,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = confirmColor ?? theme.colorScheme.primary;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: UIConstants.POP_UPS_MAX_WIDTH),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            title: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Text(message, style: theme.textTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel ?? l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: color),
                child: Text(confirmLabel ?? l10n.confirm),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// WIDGET INTERNO: Diálogo de eliminación crítica con campo de confirmación
// =============================================================================

class _DeletePermanentlyDialog extends StatefulWidget {
  final String itemName;
  final String? itemType;
  final String? warningDetail;

  const _DeletePermanentlyDialog({
    required this.itemName,
    this.itemType,
    this.warningDetail,
  });

  @override
  State<_DeletePermanentlyDialog> createState() => _DeletePermanentlyDialogState();
}

class _DeletePermanentlyDialogState extends State<_DeletePermanentlyDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final match = _confirmController.text.trim() == widget.itemName;
      if (match != _isMatch) setState(() => _isMatch = match);
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final typeLine = widget.itemType != null ? ' ${widget.itemType}' : '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UIConstants.POP_UPS_MAX_WIDTH_MEDIUM),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_forever_rounded,
                    color: theme.colorScheme.onErrorContainer, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.deletePermanentlyTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner de advertencia
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.warningDetail ?? l10n.deletePermanentlyWarning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Instrucción para escribir el nombre
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  children: [
                    TextSpan(
                        text:
                            '${l10n.deletePermanentlyInstruction}$typeLine '),
                    TextSpan(
                      text: '"${widget.itemName}"',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Campo de confirmación
              TextField(
                controller: _confirmController,
                autofocus: true,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: widget.itemName,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  // Check verde cuando coincide
                  suffixIcon: _isMatch
                      ? Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600)
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              // Solo activo cuando el nombre coincide exactamente
              onPressed:
                  _isMatch ? () => Navigator.of(context).pop(true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                disabledBackgroundColor:
                    theme.colorScheme.error.withOpacity(0.3),
              ),
              child: Text(l10n.deletePermanentlyTitle),
            ),
          ],
        ),
      ),
    );
  }
}
