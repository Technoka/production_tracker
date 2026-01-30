import 'package:cloud_firestore/cloud_firestore.dart';
// Enum para roles del sistema
enum UserRole {
  admin('admin', 'Administrador'),
  productionManager('production_manager', 'Jefe de Producción'),
  operator('operator', 'Operario'),
  accountant('accountant', 'Contable'),
  client('client', 'Cliente'),
  manufacturer('manufacturer', 'Fabricante'); // Mantener compatibilidad

  final String value;
  final String displayName;
  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;

  @deprecated
  final String role;

  final String? phone;
  final String? organizationId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? photoURL;
  final String? clientId; // Nuevo campo para identificar clientes

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.organizationId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.photoURL,
    this.clientId,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'photoURL': photoURL,
      'clientId': clientId,
    };
  }

  // Crear desde Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      phone: map['phone'] as String?,
      organizationId: map['organizationId'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      isActive: map['isActive'] as bool? ?? true,
      photoURL: map['photoURL'] as String?,
      clientId: map['clientId'] as String?,
    );
  }

  // Getters para verificar roles
  bool get isAdmin => role == UserRole.admin.value;
  bool get isProductionManager => role == UserRole.productionManager.value;
  bool get isOperator => role == UserRole.operator.value;
  bool get isAccountant => role == UserRole.accountant.value;
  bool get isClient => role == UserRole.client.value;
  bool get isManufacturer => role == UserRole.manufacturer.value;

  // Verificar si tiene permisos administrativos
  bool get hasAdminAccess => isAdmin;
  
  // Verificar si puede gestionar producción
  bool get canManageProduction => isAdmin || isProductionManager || isManufacturer;
  
  // Verificar si puede operar máquinas/procesos
  bool get canOperate => isAdmin || isProductionManager || isOperator || isManufacturer;
  
  // Verificar si puede ver información contable
  bool get canViewFinancials => isAdmin || isAccountant;

  // Obtener el nombre del rol para mostrar
  String get roleDisplayName {
    return UserRole.fromString(role).displayName;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? photoURL,
    String? clientId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      photoURL: photoURL ?? this.photoURL,
      clientId: clientId ?? this.clientId,
    );
  }
}