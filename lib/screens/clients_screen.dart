import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import '../models/client.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  void openClientForm({Client? client}) {
    final bool isEditing = client != null;

    final nameController = TextEditingController(text: client?.name ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(text: client?.address ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');

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
                  isEditing ? 'Editar Cliente' : 'Novo Cliente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();
                    final email = emailController.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe pelo menos nome e telefone.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (isEditing) {
                        client.name = name;
                        client.phone = phone;
                        client.address = address;
                        client.email = email;
                      } else {
                        AppData.clients.add(
                          Client(
                            id: AppData.nextClientId,
                            name: name,
                            phone: phone,
                            address: address,
                            email: email,
                          ),
                        );

                        AppData.nextClientId++;
                      }
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Cliente atualizado com sucesso!'
                              : 'Cliente cadastrado com sucesso!',
                        ),
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Salvar Alterações' : 'Cadastrar Cliente'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void confirmDelete(Client client) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir cliente'),
          content: Text('Deseja realmente excluir ${client.name}?'),
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
                  AppData.clients.removeWhere((item) => item.id == client.id);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente excluído com sucesso!'),
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
    final clients = AppData.clients;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: clients.isEmpty
          ? EmptyClientsView(
              onAddClient: () {
                openClientForm();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    openClientForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Cliente'),
                ),

                const SizedBox(height: 20),

                Text(
                  'Clientes cadastrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 12),

                ...clients.map((client) {
                  return ClientCard(
                    client: client,
                    onEdit: () {
                      openClientForm(client: client);
                    },
                    onDelete: () {
                      confirmDelete(client);
                    },
                  );
                }),
              ],
            ),
    );
  }
}

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClientCard({
    super.key,
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person,
              color: AppColors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 6),

                InfoLine(
                  icon: Icons.phone_outlined,
                  text: client.phone,
                ),

                if (client.address.isNotEmpty)
                  InfoLine(
                    icon: Icons.location_on_outlined,
                    text: client.address,
                  ),

                if (client.email.isNotEmpty)
                  InfoLine(
                    icon: Icons.email_outlined,
                    text: client.email,
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

class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoLine({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.darkGray,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGray,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyClientsView extends StatelessWidget {
  final VoidCallback onAddClient;

  const EmptyClientsView({
    super.key,
    required this.onAddClient,
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
                Icons.people_outline,
                size: 56,
                color: AppColors.primary,
              ),

              const SizedBox(height: 16),

              Text(
                'Nenhum cliente cadastrado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.graphite,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Cadastre seu primeiro cliente para começar a organizar seus serviços.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGray,
                    ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: onAddClient,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}