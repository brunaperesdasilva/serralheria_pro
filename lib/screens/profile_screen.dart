import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController responsibleNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    companyNameController.text = AppData.companyProfile.companyName;
    responsibleNameController.text = AppData.companyProfile.responsibleName;
    phoneController.text = AppData.companyProfile.phone;
    emailController.text = AppData.companyProfile.email;
  }

  @override
  void dispose() {
    companyNameController.dispose();
    responsibleNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void saveProfile() {
    final companyName = companyNameController.text.trim();
    final responsibleName = responsibleNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da empresa.')),
      );
      return;
    }

    setState(() {
      AppData.companyProfile.companyName = companyName;
      AppData.companyProfile.responsibleName = responsibleName;
      AppData.companyProfile.phone = phone;
      AppData.companyProfile.email = email;
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo com sucesso!')),
    );
  }

  // Função para gerar as iniciais do nome
  String getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppData.companyProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar',
              onPressed: () {
                setState(() {
                  isEditing = false;
                  _loadData();
                });
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Card do topo com Logo dinâmica
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
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
              children: [
                // Área da Logo (Agora dinâmica)
                GestureDetector(
                  onTap: isEditing
                      ? () {
                          // Simula a ação de trocar foto
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Upload de imagem será implementado na próxima fase.',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          getInitials(profile.companyName),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  profile.companyName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dados da empresa',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkGray,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Área de Informações
          Container(
            padding: const EdgeInsets.all(20),
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
            child: isEditing ? _buildEditMode() : _buildViewMode(),
          ),

          const SizedBox(height: 24),

          if (isEditing)
            ElevatedButton.icon(
              onPressed: saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar Alterações'),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.business_outlined,
          label: 'Empresa',
          value: AppData.companyProfile.companyName,
        ),
        const Divider(height: 24),
        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Responsável',
          value: AppData.companyProfile.responsibleName,
        ),
        const Divider(height: 24),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Telefone',
          value: AppData.companyProfile.phone,
        ),
        const Divider(height: 24),
        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'E-mail',
          value: AppData.companyProfile.email,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGray,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        TextField(
          controller: companyNameController,
          decoration: const InputDecoration(
            labelText: 'Nome da empresa',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: responsibleNameController,
          decoration: const InputDecoration(
            labelText: 'Responsável',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
      ],
    );
  }
}