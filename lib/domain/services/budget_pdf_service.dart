import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/budget.dart';
import '../../models/client.dart';
import '../../models/company_profile.dart';

abstract final class BudgetPdfService {
  static Future<Uint8List> generate({
    required Budget budget,
    required CompanyProfile company,
    Client? client,
  }) async {
    final document = pw.Document(
      title: 'Orcamento - ${budget.clientName}',
      author: company.companyName,
      creator: company.companyName,
    );
    final logo = _readLogo(company.logoBase64);
    final accent = PdfColor.fromHex('#7A0E0E');
    final graphite = PdfColor.fromHex('#202124');
    final gray = PdfColor.fromHex('#5F6368');
    final line = PdfColor.fromHex('#B9BDC3');
    final soft = PdfColor.fromHex('#F5F6F7');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (context) => pw.Column(children: [
          _companyHeader(
            company: company,
            budget: budget,
            logo: logo,
            graphite: graphite,
            gray: gray,
            line: line,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'ORCAMENTO',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: graphite,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 8),
        ]),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 7),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: line, width: 0.7)),
          ),
          child: pw.Row(children: [
            pw.Expanded(
              child: pw.Text(company.companyName,
                  style: pw.TextStyle(fontSize: 7.5, color: gray)),
            ),
            pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: gray)),
          ]),
        ),
        build: (context) => [
          _clientGrid(client, budget, graphite, line, soft),
          pw.SizedBox(height: 10),
          _itemsTable(budget, graphite, soft, line),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _totals(budget, accent, graphite, line),
          ),
          if (budget.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _observations(budget, graphite, line),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _companyHeader({
    required CompanyProfile company,
    required Budget budget,
    required pw.MemoryImage? logo,
    required PdfColor graphite,
    required PdfColor gray,
    required PdfColor line,
  }) =>
      pw.Container(
        decoration:
            pw.BoxDecoration(border: pw.Border.all(color: line, width: 0.8)),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 108,
                padding: const pw.EdgeInsets.all(10),
                alignment: pw.Alignment.center,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.Container(width: 0.8, color: line),
            ],
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(company.companyName,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: graphite)),
                    pw.SizedBox(height: 3),
                    if (company.cnpj.trim().isNotEmpty)
                      pw.Text('CNPJ: ${company.cnpj}',
                          style: pw.TextStyle(fontSize: 8.5, color: gray)),
                    if (company.responsibleName.trim().isNotEmpty)
                      pw.Text('Responsavel: ${company.responsibleName}',
                          style: pw.TextStyle(fontSize: 8.5, color: gray)),
                    if (_contactLine(company).isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(_contactLine(company),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8.5, color: gray)),
                    ],
                  ],
                ),
              ),
            ),
            pw.Container(width: 0.8, color: line),
            pw.Container(
              width: 98,
              child: pw.Column(children: [
                _headerInfo('CRIADO EM', _date(budget.createdAt), line),
                _headerInfo('VALIDO ATE', _date(budget.validUntil), line,
                    last: budget.id == null),
                if (budget.id != null)
                  _headerInfo('ORCAMENTO N.', '#${budget.id}', line,
                      last: true),
              ]),
            ),
          ],
        ),
      );

  static pw.Widget _headerInfo(String label, String value, PdfColor line,
          {bool last = false}) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: pw.BoxDecoration(
          border: last
              ? null
              : pw.Border(bottom: pw.BorderSide(color: line, width: 0.8)),
        ),
        child: pw.Column(children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              textAlign: pw.TextAlign.center,
              style:
                  pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static pw.Widget _clientGrid(Client? client, Budget budget, PdfColor graphite,
          PdfColor line, PdfColor soft) =>
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: line)),
        child: pw.Column(children: [
          _bar('DADOS DO CLIENTE', graphite),
          pw.Row(children: [
            _field('CLIENTE', budget.clientName, line,
                flex: client?.phone.trim().isNotEmpty == true ? 3 : 1),
            if (client?.phone.trim().isNotEmpty == true)
              _field('TELEFONE', client!.phone, line, flex: 2),
          ]),
          if (client?.email.trim().isNotEmpty == true)
            pw.Row(children: [
              _field('E-MAIL', client!.email, line, flex: 1),
            ]),
          if (client?.address.trim().isNotEmpty == true)
            pw.Row(children: [
              _field('ENDERECO', client!.address, line,
                  flex: 1, bottomBorder: false),
            ]),
        ]),
      );

  static pw.Widget _field(String label, String value, PdfColor line,
          {required int flex, bool bottomBorder = true}) =>
      pw.Expanded(
        flex: flex,
        child: pw.Container(
          constraints: const pw.BoxConstraints(minHeight: 34),
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: line, width: 0.6),
              bottom: bottomBorder
                  ? pw.BorderSide(color: line, width: 0.6)
                  : pw.BorderSide.none,
            ),
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
              ]),
        ),
      );

  static pw.Widget _itemsTable(
          Budget budget, PdfColor graphite, PdfColor soft, PdfColor line) =>
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: line, width: 0.7),
        headerDecoration: pw.BoxDecoration(color: graphite),
        headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8.3),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        oddRowDecoration: pw.BoxDecoration(color: soft),
        columnWidths: const {
          0: pw.FlexColumnWidth(0.8),
          1: pw.FlexColumnWidth(4.2),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(1.5),
          4: pw.FlexColumnWidth(1.5),
        },
        cellAlignments: const {
          0: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
        headers: const ['ITEM', 'DESCRICAO', 'QTD.', 'PRECO UNIT.', 'TOTAL'],
        data: budget.items.asMap().entries.map((entry) {
          final item = entry.value;
          return [
            (entry.key + 1).toString(),
            item.description,
            _quantity(item.quantity),
            _currency(item.unitValue * (1 + budget.profitMargin / 100)),
            _currency(item.total * (1 + budget.profitMargin / 100)),
          ];
        }).toList(),
      );

  static pw.Widget _totals(
          Budget budget, PdfColor accent, PdfColor graphite, PdfColor line) =>
      pw.Container(
        width: 230,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: line)),
        child: pw.Column(children: [
          _totalLine('Subtotal',
              budget.baseValue * (1 + budget.profitMargin / 100), line),
          if (budget.discount > 0)
            _totalLine('Desconto', -budget.discount, line),
          if (budget.additionalValue > 0)
            _totalLine('Adicional', budget.additionalValue, line),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: graphite,
              border: pw.Border(
                top: pw.BorderSide(color: accent, width: 2),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: pw.Row(children: [
              pw.Expanded(
                  child: pw.Text('TOTAL FINAL',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold))),
              pw.Text(_currency(budget.finalValue),
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        ]),
      );

  static pw.Widget _totalLine(String label, double value, PdfColor line) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.6))),
        child: pw.Row(children: [
          pw.Expanded(
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 8))),
          pw.Text(_currency(value),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static pw.Widget _observations(
          Budget budget, PdfColor graphite, PdfColor line) =>
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: line)),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _bar('OBSERVACOES', graphite),
              pw.Container(
                width: double.infinity,
                constraints: const pw.BoxConstraints(minHeight: 48),
                padding: const pw.EdgeInsets.all(9),
                child: pw.Text(budget.notes,
                    style: const pw.TextStyle(fontSize: 8.5)),
              ),
            ]),
      );

  static pw.Widget _bar(String text, PdfColor color) => pw.Container(
        width: double.infinity,
        color: color,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: pw.Text(text,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.MemoryImage? _readLogo(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return pw.MemoryImage(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  static String _contactLine(CompanyProfile company) => [
        company.phone,
        company.email
      ].where((value) => value.trim().isNotEmpty).join('  |  ');

  static String _currency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  static String _quantity(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceAll('.', ',');
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
