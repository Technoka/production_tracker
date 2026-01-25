import 'package:flutter/material.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/validation_config_model.dart';
import 'simple_approval_dialog.dart';
import 'text_validation_dialog.dart';
import 'quantity_text_dialog.dart';
import 'checklist_dialog.dart';
import 'photo_validation_dialog.dart';
import 'multi_approval_dialog.dart';
import 'custom_parameters_dialog.dart';

/// Manager central que muestra el diálogo de validación apropiado
/// según el tipo de validación configurado en la transición
class ValidationDialogManager {
  /// Muestra el diálogo de validación correspondiente y retorna los datos validados
  /// 
  /// Retorna:
  /// - ValidationDataModel si el usuario completó y confirmó la validación
  /// - null si el usuario canceló
  static Future<ValidationDataModel?> showValidationDialog({
    required BuildContext context,
    required StatusTransitionModel transition,
    required BatchProductModel product,
  }) async {
    switch (transition.validationType) {
      case ValidationType.simpleApproval:
        return await _showSimpleApprovalDialog(
          context,
          transition,
          product,
        );

      case ValidationType.textRequired:
        return await _showTextDialog(
          context,
          transition,
          product,
          isRequired: true,
        );

      case ValidationType.textOptional:
        return await _showTextDialog(
          context,
          transition,
          product,
          isRequired: false,
        );

      case ValidationType.quantityAndText:
        return await _showQuantityTextDialog(
          context,
          transition,
          product,
        );

      case ValidationType.checklist:
        return await _showChecklistDialog(
          context,
          transition,
          product,
        );

      case ValidationType.photoRequired:
        return await _showPhotoDialog(
          context,
          transition,
          product,
        );

      case ValidationType.multiApproval:
        return await _showMultiApprovalDialog(
          context,
          transition,
          product,
        );
        case ValidationType.customParameters:
  return await _showCustomParametersDialog(
    context,
    transition,
    product,
  );
    }
  }

  static Future<ValidationDataModel?> _showSimpleApprovalDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      builder: (context) => SimpleApprovalDialog(
        transition: transition,
        product: product,
      ),
    );
  }

  static Future<ValidationDataModel?> _showTextDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product, {
    required bool isRequired,
  }) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TextValidationDialog(
        transition: transition,
        product: product,
        isRequired: isRequired,
      ),
    );
  }

  static Future<ValidationDataModel?> _showQuantityTextDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuantityTextDialog(
        transition: transition,
        product: product,
      ),
    );
  }

  static Future<ValidationDataModel?> _showChecklistDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChecklistDialog(
        transition: transition,
        product: product,
      ),
    );
  }

  static Future<ValidationDataModel?> _showPhotoDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhotoValidationDialog(
        transition: transition,
        product: product,
      ),
    );
  }

  static Future<ValidationDataModel?> _showMultiApprovalDialog(
    BuildContext context,
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    return await showDialog<ValidationDataModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiApprovalDialog(
        transition: transition,
        product: product,
      ),
    );
  }

  static Future<ValidationDataModel?> _showCustomParametersDialog(
  BuildContext context,
  StatusTransitionModel transition,
  BatchProductModel product,
) async {
  return await showDialog<ValidationDataModel>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CustomParametersDialog(
      transition: transition,
      product: product,
    ),
  );
}
}