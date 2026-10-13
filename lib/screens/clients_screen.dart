import 'package:flutter/material.dart';

import '../core/app_card.dart';
import '../core/app_colors.dart';
import '../core/widgets/app_dialogs.dart';
import '../data/app_data.dart';
import '../models/client.dart';

class ClientsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ClientsScreen({super.key, this.onBack});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  void openClientForm({Client? client}) {
    final bool isEditing = client != null;

    final nameController = TextEditingController(text: client?.name ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController =
        TextEditingController(text: client?.address ?? '');
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
                  onPressed: () async {
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

                    if (isEditing) {
                      client.name = name;
                      client.phone = phone;
                      client.address = address;
                      client.email = email;

                      await AppData.updateClient(client);
                    } else {
                      await AppData.addClient(
                        Client(
                          name: name,
                          phone: phone,
                          address: address,
                          email: email,
                        ),
                      );
                    }

                    if (!context.mounted) return;

                    setState(() {});

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
                  child: Text(
                      isEditing ? 'Salvar Alterações' : 'Cadastrar Cliente'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> confirmDelete(Client client) async {
    final id = client.id;
    if (id == null) {
      _message('Este cliente ainda não foi sincronizado. Tente novamente.');
      return;
    }
    final confirmed = await AppDialogs.confirmDelete(
      context,
      title: 'Excluir cliente',
      message:
          'Deseja realmente excluir ${client.name}? Os orçamentos e agendamentos existentes serão mantidos.',
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(
      duration: Duration(seconds: 30),
      content: Row(children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text('Excluindo cliente...'),
      ]),
    ));

    try {
      await AppData.deleteClient(id);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      setState(() {});
      messenger.showSnackBar(
        const SnackBar(content: Text('Cliente excluído com sucesso!')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      _message('Não foi possível excluir o cliente. Verifique a conexão.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final clients = AppData.clients;

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar adicionada conforme solicitado
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
                onPressed: widget.onBack,
              ),
        title: const Text('Clientes'),
      ),
      body: clients.isEmpty
          ? EmptyClientsView(
              onAddClient: () {
                openClientForm();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        openClientForm();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Cliente'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Clientes cadastrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),
                const SizedBox(height: 16),
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 12),
                InfoLine(
                  icon: Icons.phone_outlined,
                  text: client.phone,
                ),
                if (client.address.isNotEmpty) const SizedBox(height: 8),
                if (client.address.isNotEmpty)
                  InfoLine(
                    icon: Icons.location_on_outlined,
                    text: client.address,
                  ),
                if (client.email.isNotEmpty) const SizedBox(height: 8),
                if (client.email.isNotEmpty)
                  InfoLine(
                    icon: Icons.email_outlined,
                    text: client.email,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Editar',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  tooltip: 'Excluir',
                ),
              ],
            ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkGray,
                  height: 1.4,
                ),
          ),
        ),
      ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 56,
              color: AppColors.darkGray,
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
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: onAddClient,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
