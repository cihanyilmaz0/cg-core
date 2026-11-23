import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/report_summary_model.dart';

class ReportExportService {
  ReportExportService._();

  static Future<void> exportToPdf({
    required ReportSummaryModel report,
    required String businessName,
  }) async {
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final periodTitle = DateFormatter.formatMonthYear(DateTime(report.year, report.month));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Aylık Finansal Gider Raporu - $periodTitle',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Text(
                'CG Core',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.Divider(height: 24),

          // Özet Kartlar
          pw.Text('Genel Özet', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Kalem', 'Tutar'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Bu Ay Personel Ödemeleri', CurrencyFormatter.formatCents(report.monthlyPersonnelCents)],
              ['Bu Ay Araç Giderleri', CurrencyFormatter.formatCents(report.monthlyVehicleCents)],
              ['Bu Ay Genel İşletme Giderleri', CurrencyFormatter.formatCents(report.monthlyGeneralCents)],
              ['AYLIK TOPLAM GİDER', CurrencyFormatter.formatCents(report.monthlyTotalCents)],
              ['${report.year} YILI TOPLAM GİDER', CurrencyFormatter.formatCents(report.yearlyTotalCents)],
            ],
          ),
          pw.SizedBox(height: 20),

          // Kategori Dağılımı
          if (report.categoryBreakdown.isNotEmpty) ...[
            pw.Text(
              'Kategori Bazlı Dağılım ($periodTitle)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Kategori', 'Tutar'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              data: report.categoryBreakdown
                  .map((c) => [c.name, CurrencyFormatter.formatCents(c.amountCents)])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Personel Maliyetleri
          if (report.personnelCosts.isNotEmpty) ...[
            pw.Text(
              'Personel Bazlı Maliyetler ($periodTitle)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Personel', 'Görev / Detay', 'Toplam Ödenen'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              data: report.personnelCosts
                  .map((p) => [p.title, p.subtitle, CurrencyFormatter.formatCents(p.amountCents)])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Araç Maliyetleri
          if (report.vehicleCosts.isNotEmpty) ...[
            pw.Text(
              'Araç Bazlı Maliyetler ($periodTitle)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Plaka', 'Araç Bilgisi', 'Toplam Gider'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.amber800),
              data: report.vehicleCosts
                  .map((v) => [v.title, v.subtitle, CurrencyFormatter.formatCents(v.amountCents)])
                  .toList(),
            ),
          ],
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'cg_core_rapor_${report.year}_${report.month}.pdf',
    );
  }

  static Future<void> exportToExcel({
    required ReportSummaryModel report,
    required String businessName,
  }) async {
    final excel = Excel.createExcel();
    final periodTitle = DateFormatter.formatMonthYear(DateTime(report.year, report.month));

    // 1. Özet Sayfası
    final summarySheet = excel['Özet'];
    excel.setDefaultSheet('Özet');
    summarySheet.appendRow([TextCellValue('$businessName - Gider Raporu ($periodTitle)')]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([TextCellValue('Kalem'), TextCellValue('Tutar (TL)')]);
    summarySheet.appendRow([
      TextCellValue('Aylık Personel Ödemeleri'),
      DoubleCellValue(CurrencyFormatter.centsToLira(report.monthlyPersonnelCents)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Aylık Araç Giderleri'),
      DoubleCellValue(CurrencyFormatter.centsToLira(report.monthlyVehicleCents)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Aylık Genel İşletme Giderleri'),
      DoubleCellValue(CurrencyFormatter.centsToLira(report.monthlyGeneralCents)),
    ]);
    summarySheet.appendRow([
      TextCellValue('AYLIK TOPLAM GİDER'),
      DoubleCellValue(CurrencyFormatter.centsToLira(report.monthlyTotalCents)),
    ]);
    summarySheet.appendRow([
      TextCellValue('${report.year} YILI TOPLAM GİDER'),
      DoubleCellValue(CurrencyFormatter.centsToLira(report.yearlyTotalCents)),
    ]);

    // 2. Kategori Dağılımı
    final catSheet = excel['Kategoriler'];
    catSheet.appendRow([TextCellValue('Kategori'), TextCellValue('Tutar (TL)')]);
    for (final c in report.categoryBreakdown) {
      catSheet.appendRow([
        TextCellValue(c.name),
        DoubleCellValue(CurrencyFormatter.centsToLira(c.amountCents)),
      ]);
    }

    // 3. Personel Maliyetleri
    final empSheet = excel['Personel'];
    empSheet.appendRow([
      TextCellValue('Personel'),
      TextCellValue('Görev / Detay'),
      TextCellValue('Tutar (TL)'),
    ]);
    for (final p in report.personnelCosts) {
      empSheet.appendRow([
        TextCellValue(p.title),
        TextCellValue(p.subtitle),
        DoubleCellValue(CurrencyFormatter.centsToLira(p.amountCents)),
      ]);
    }

    // 4. Araç Maliyetleri
    final vehSheet = excel['Araçlar'];
    vehSheet.appendRow([
      TextCellValue('Plaka'),
      TextCellValue('Araç Bilgisi'),
      TextCellValue('Tutar (TL)'),
    ]);
    for (final v in report.vehicleCosts) {
      vehSheet.appendRow([
        TextCellValue(v.title),
        TextCellValue(v.subtitle),
        DoubleCellValue(CurrencyFormatter.centsToLira(v.amountCents)),
      ]);
    }

    // Varsayılan boş 'Sheet1' varsa kaldır
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/cg_core_rapor_${report.year}_${report.month}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: '$businessName - $periodTitle Gider Raporu',
      ),
    );
  }
}
