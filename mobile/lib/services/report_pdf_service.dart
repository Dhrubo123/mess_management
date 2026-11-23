import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportPdfService {
  static Future<void> generateAndShare(Map<String, dynamic> summary) async {
    final pdf = pw.Document();
    final mess = (summary['mess'] as Map<String, dynamic>?) ?? {};
    final month = (summary['month'] as Map<String, dynamic>?) ?? {};
    final totals = (summary['totals'] as Map<String, dynamic>?) ?? {};
    final members = (summary['members'] as List?) ?? [];
    final bills = (summary['fixed_bills'] as List?) ?? [];

    final messName = mess['name']?.toString() ?? 'Ctg Mess';
    final area = '${mess['area'] ?? ''}, ${mess['city'] ?? 'Chattogram'}';
    final monthLabel = month['label']?.toString() ?? '';

    const emerald = PdfColor.fromInt(0xFF0A5C48);
    const emeraldLight = PdfColor.fromInt(0xFFE6F4F0);
    const slate = PdfColor.fromInt(0xFF475569);
    const border = PdfColor.fromInt(0xFFE2E8F0);
    const danger = PdfColor.fromInt(0xFFDC2626);

    pw.Widget statBox(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: emeraldLight,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 9, color: slate)),
              pw.SizedBox(height: 4),
              pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: emerald)),
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: emerald,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(messName, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(area, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('MONTHLY STATEMENT', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(monthLabel, style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary KPIs
          pw.Row(
            children: [
              statBox('Meal Rate', 'BDT ${totals['meal_rate']}/meal'),
              pw.SizedBox(width: 8),
              statBox('Total Meals', '${totals['total_meals']}'),
              pw.SizedBox(width: 8),
              statBox('Total Bazar', 'BDT ${totals['total_bazar']}'),
              pw.SizedBox(width: 8),
              statBox('Cash in Hand', 'BDT ${totals['cash_in_hand']}'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              statBox('Meal Fund Collected', 'BDT ${totals['total_meal_deposits']}'),
              pw.SizedBox(width: 8),
              statBox('Fixed Bills / Member', 'BDT ${totals['per_member_fixed_share']}'),
              pw.SizedBox(width: 8),
              statBox('Active Members', '${totals['member_count']}'),
            ],
          ),
          pw.SizedBox(height: 18),

          // Member Breakdown Table
          pw.Text('Member Meal & Money Breakdown', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: emerald),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            border: pw.TableBorder.all(color: border, width: 0.6),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            headers: ['Member', 'Meals', 'Meal Cost', 'Meal Given', 'Meal Bal', 'Total Cost', 'Total Paid', 'Final Status'],
            data: members.map((m) {
              final mealBal = (m['meal_balance'] as num).toDouble();
              final netBal = (m['net_balance'] as num).toDouble();
              return [
                m['name']?.toString() ?? '',
                '${m['total_meals']}',
                '${m['meal_cost']}',
                '${m['meal_deposit']}',
                mealBal >= 0 ? '+${mealBal.toStringAsFixed(0)}' : '-${mealBal.abs().toStringAsFixed(0)}',
                '${m['total_cost']}',
                '${m['total_paid']}',
                netBal >= 0 ? 'Refund +${netBal.toStringAsFixed(0)}' : 'Due -${netBal.abs().toStringAsFixed(0)}',
              ];
            }).toList(),
          ),

          if (bills.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Itemized Fixed Monthly Bills', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: emerald),
              headerDecoration: const pw.BoxDecoration(color: emeraldLight),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              border: pw.TableBorder.all(color: border, width: 0.6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Bill Title', 'Category', 'Total (BDT)', 'Per Member (BDT)'],
              data: bills.map((b) => [
                b['title']?.toString() ?? '',
                (b['category']?.toString() ?? '').toUpperCase(),
                '${b['total_amount']}',
                '${b['per_member']}',
              ]).toList(),
            ),
          ],

          pw.SizedBox(height: 24),
          pw.Divider(color: border),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated by Ctg Mess • Chattogram', style: pw.TextStyle(fontSize: 9, color: slate)),
              pw.Text('Invite Code: ${mess['invite_code'] ?? ''}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: danger)),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeName = '${messName}_$monthLabel'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$messName — $monthLabel Monthly Report (Generated by Ctg Mess)',
      ),
    );
  }
}
