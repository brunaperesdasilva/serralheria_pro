import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:serralheria_pro/models/company_profile.dart';

import '../core/app_card.dart';
import '../core/app_auth.dart';
import '../core/app_colors.dart';
import '../core/widgets/company_avatar.dart';
import '../data/app_data.dart';
import '../data/cloud_data_bootstrap.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController responsibleNameController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cnpjController = TextEditingController();

  bool isEditing = false;
  String? _logoBase64;

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
    cnpjController.text = AppData.companyProfile.cnpj;
    _logoBase64 = AppData.companyProfile.logoBase64;
  }

  @override
  void dispose() {
    companyNameController.dispose();
    responsibleNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cnpjController.dispose();
    super.dispose();
  }

  void saveProfile() async {
    final companyName = companyNameController.text.trim();
    final responsibleName = responsibleNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final cnpj = cnpjController.text.trim();

    if (companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da empresa.')),
      );
      return;
    }

    final newProfile = CompanyProfile(
      id: AppData.companyProfile.id,
      companyName: companyName,
      responsibleName: responsibleName,
      phone: phone,
      email: email,
      cnpj: cnpj,
      logoBase64: _logoBase64,
    );

    await AppData.saveProfile(newProfile);

    if (!mounted) return;
    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo com sucesso!')),
    );
  }

  String getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _pickLogo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 700000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Escolha uma imagem menor que 700 KB.'),
      ));
      return;
    }
    setState(() => _logoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppData.companyProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              CloudDataBootstrap.reset();
              await AppAuth.repository.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
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
          AppCard(
            child: Column(
              children: [
                CompanyAvatar(
                  logoBase64: _logoBase64,
                  fallback: getInitials(profile.companyName),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(_logoBase64 == null
                            ? 'Adicionar logotipo'
                            : 'Trocar logotipo'),
                      ),
                      if (_logoBase64 != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _logoBase64 = null),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remover'),
                        ),
                    ],
                  ),
                ],
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
          AppCard(
            child: isEditing ? _buildEditMode() : _buildViewMode(),
          ),
          const SizedBox(height: 24),
          if (isEditing)
            ElevatedButton.icon(
              onPressed: saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar Alterações'),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          icon: Icons.badge_outlined,
          label: 'CNPJ',
          value: AppData.companyProfile.cnpj.isEmpty
              ? 'Não informado'
              : AppData.companyProfile.cnpj,
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
          controller: cnpjController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CNPJ',
            hintText: '00.000.000/0000-00',
            prefixIcon: Icon(Icons.badge_outlined),
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
