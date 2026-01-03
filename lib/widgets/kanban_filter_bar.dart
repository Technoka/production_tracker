import 'package:flutter/material.dart';

class KanbanFilterBar extends StatelessWidget {
  final String? searchQuery;
  final bool showOnlyBlocked;
  final Function(String) onSearchChanged;
  final Function(bool) onBlockedFilterChanged;
  final VoidCallback? onClearFilters;

  const KanbanFilterBar({
    Key? key,
    this.searchQuery,
    required this.showOnlyBlocked,
    required this.onSearchChanged,
    required this.onBlockedFilterChanged,
    this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = (searchQuery?.isNotEmpty ?? false) || showOnlyBlocked;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Campo de búsqueda
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchQuery?.isNotEmpty ?? false
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => onSearchChanged(''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Filtro de bloqueados
              FilterChip(
                label: const Text('Bloqueados'),
                selected: showOnlyBlocked,
                onSelected: onBlockedFilterChanged,
                avatar: Icon(
                  Icons.block,
                  size: 16,
                  color: showOnlyBlocked ? Colors.white : Colors.red,
                ),
                selectedColor: Colors.red.shade700,
                labelStyle: TextStyle(
                  color: showOnlyBlocked ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
              
              // Botón limpiar filtros
              if (hasActiveFilters && onClearFilters != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Limpiar filtros',
                  onPressed: onClearFilters,
                  color: Colors.grey.shade700,
                ),
              ],
            ],
          ),
          
          // Indicador de filtros activos
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getFilterDescription(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFilterDescription() {
    final filters = <String>[];
    
    if (searchQuery?.isNotEmpty ?? false) {
      filters.add('Búsqueda: "$searchQuery"');
    }
    
    if (showOnlyBlocked) {
      filters.add('Solo bloqueados');
    }
    
    return filters.join(' • ');
  }
}