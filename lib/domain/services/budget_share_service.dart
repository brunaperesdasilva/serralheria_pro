import 'dart:ui';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/budget.dart';
import '../../models/client.dart';
import '../../models/company_profile.dart';
import 'budget_pdf_service.dart';

abstract final class BudgetShareService {
  static Future<void> sharePdf({
    required Budget budget,
    required CompanyProfile company,
    required Client client,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await BudgetPdfService.generate(
      budget: budget,
      company: company,
      client: client,
    );
    const fileName = 'Orçamento.pdf';
    await SharePlus.instance.share(
      ShareParams(
        title: 'Orçamento - ${company.companyName}',
        subject: 'Orçamento para ${client.name}',
        text: message(budget: budget, company: company, client: client),
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static Future<bool> openWhatsApp({
    required Budget budget,
    required CompanyProfile company,
    required Client client,
  }) async {
    final phone = normalizedPhone(client.phone);
    if (phone == null) return false;
    final text = Uri.encodeComponent(
      message(budget: budget, company: company, client: client),
    );
    final uri = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    try {
      return await launchUrl(uri,
          mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {
      return false;
    }
  }

  static String message({
    required Budget budget,
    required CompanyProfile company,
    required Client client,
  }) =>
      'Olá! Tudo bem? Segue o orçamento, válido até '
      '${_date(budget.validUntil)}. Qualquer dúvida estarei à disposição! :)';

  static String? normalizedPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 || digits.length == 11) digits = '55$digits';
    if (digits.length < 12 || digits.length > 13) return null;
    return digits;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
