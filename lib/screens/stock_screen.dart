import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import '../models/material_item.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double parseDouble(String value) {
    final cleanValue = value.replaceAll(',', '.').trim();
    return double.tryParse(cleanValue) ?? 0.0;
  }

  int parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  void openMaterialForm({MaterialItem? material}) {
    final bool isEditing = material != null;

    final nameController = TextEditingController(text: material?.name ?? '');
    final quantityController = TextEditingController(
      text: material?.quantity.toString() ?? '',
    );
    final minimumController = TextEditingController(
      text: material?.minimumQuantity.toString() ?? '',
    );
    final costController = TextEditingController(
      text: material != null ? material.costPrice.toStringAsFixed(2) : '',
    );
    final saleController = TextEditingController(
      text: material != null ? material.salePrice.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Editar Material' : 'Novo Material',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do material',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade disponível',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: minimumController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade mínima',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custo',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: saleController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Preço de venda',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final quantity = parseInt(quantityController.text);
                    final minimum = parseInt(minimumController.text);
                    final cost = parseDouble(costController.text);
                    final sale = parseDouble(saleController.text);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o nome do material.'),
                        ),
                      );
                      return;
                    }

                    if (quantity < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe uma quantidade válida.'),
                        ),
                      );
                      return;
                    }

                    if (minimum < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe uma quantidade mínima válida.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (isEditing) {
                        material.name = name;
                        material.quantity = quantity;
                        material.minimumQuantity = minimum;
                        material.costPrice = cost;
                        material.salePrice = sale;
                      } else {
                        AppData.materials.add(
                          MaterialItem(
                            id: AppData.nextMaterialId,
                            name: name,
                            quantity: quantity,
                            minimumQuantity: minimum,
                            costPrice: cost,
                            salePrice: sale,
                          ),
                        );

                        AppData.nextMaterialId++;
                      }
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Material atualizado com sucesso!'
                              : 'Material cadastrado com sucesso!',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    isEditing ? 'Salvar Alterações' : 'Cadastrar Material',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void confirmDelete(MaterialItem material) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir material'),
          content: Text('Deseja realmente excluir ${material.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  AppData.materials.removeWhere(
                    (item) => item.id == material.id,
                  );
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Material excluído com sucesso!'),
                  ),
                );
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = AppData.materials;
    final lowStockCount = AppData.lowStockCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: materials.isEmpty
          ? EmptyStockView(
              onAddMaterial: () {
                openMaterialForm();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (lowStockCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lowStockCount == 1
                                ? 'Existe 1 material com estoque baixo.'
                                : 'Existem $lowStockCount materiais com estoque baixo.',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton.icon(
                  onPressed: () {
                    openMaterialForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Material'),
                ),

                const SizedBox(height: 20),

                Text(
                  'Materiais cadastrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 12),

                ...materials.map((material) {
                  return MaterialCard(
                    material: material,
                    formattedCost: formatCurrency(material.costPrice),
                    formattedSale: formatCurrency(material.salePrice),
                    onEdit: () {
                      openMaterialForm(material: material);
                    },
                    onDelete: () {
                      confirmDelete(material);
                    },
                  );
                }),
              ],
            ),
    );
  }
}

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  final String formattedCost;
  final String formattedSale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaterialCard({
    super.key,
    required this.material,
    required this.formattedCost,
    required this.formattedSale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool lowStock = material.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: lowStock ? AppColors.danger : AppColors.primary,
            size: 36,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 6),

                Text('Quantidade: ${material.quantity}'),
                Text('Mínimo: ${material.minimumQuantity}'),
                Text('Custo: $formattedCost'),
                Text('Preço: $formattedSale'),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lowStock
                        ? AppColors.danger.withOpacity(0.12)
                        : AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lowStock ? 'Estoque Baixo' : 'Estoque OK',
                    style: TextStyle(
                      color: lowStock ? AppColors.danger : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyStockView extends StatelessWidget {
  final VoidCallback onAddMaterial;

  const EmptyStockView({
    super.key,
    required this.onAddMaterial,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primary,
              ),

              const SizedBox(height: 16),

              Text(
                'Nenhum material cadastrado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.graphite,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Cadastre materiais para controlar o estoque da serralheria.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGray,
                    ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: onAddMaterial,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Material'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}