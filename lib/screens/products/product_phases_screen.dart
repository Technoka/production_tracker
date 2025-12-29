import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/phase_progress_widget.dart';

class ProductPhasesScreen extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String productId;
  final String productName;
  final UserModel currentUser;

  const ProductPhasesScreen({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    required this.productName,
    required this.currentUser,
  }) : super(key: key);

  bool get _isReadOnly {
    final role = currentUser.role.toLowerCase();
    return role == 'client' || role == 'contable';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fases de Producción'),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: PhaseProgressWidget(
        organizationId: organizationId,
        projectId: projectId,
        productId: productId,
        currentUser: currentUser,
        isReadOnly: _isReadOnly,
      ),
    );
  }
}