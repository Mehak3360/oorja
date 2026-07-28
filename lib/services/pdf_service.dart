import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_model.dart';
import '../models/home_model.dart';

class PdfService {
  Future<void> generateAndShareReport(ReportModel report, HomeModel? home) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('OORJA — Monthly Energy Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(
            'Generated on ${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          if (home != null) ...[
            pw.Header(level: 1, text: 'Home Summary'),
            _pdfRow('House Type', home.houseType),
            _pdfRow('City', home.city),
            _pdfRow('Family Members', '${home.familyMembers}'),
            _pdfRow('Electricity Provider', home.electricityProvider),
            pw.SizedBox(height: 16),
          ],

          pw.Header(level: 1, text: 'Budget Summary'),
          _pdfRow('Estimated Bill', 'Rs. ${report.totalCost.toStringAsFixed(0)}'),
          if (home != null)
            _pdfRow('Monthly Budget', 'Rs. ${home.monthlyBudget.toStringAsFixed(0)}'),
          _pdfRow('Total Units', '${report.totalUnits.toStringAsFixed(1)} kWh'),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Energy Health Score'),
          pw.Text('${report.energyHealthScore.toStringAsFixed(0)} / 100',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Carbon Footprint'),
          pw.Text('${report.carbonFootprintKg.toStringAsFixed(1)} kg CO2/month'),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Room-wise Breakdown'),
          pw.Table.fromTextArray(
            headers: ['Room', 'Units (kWh)'],
            data: report.roomWiseBreakdown.entries
                .map((e) => [e.key, e.value.toStringAsFixed(1)])
                .toList(),
          ),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Top 5 Energy Consuming Appliances'),
          pw.Table.fromTextArray(
            headers: ['Appliance', 'Units (kWh)', 'Cost (Rs.)'],
            data: report.top5Appliances
                .map((a) => [
                      a['name'].toString(),
                      (a['monthlyUnits'] as num).toStringAsFixed(1),
                      (a['monthlyCost'] as num).toStringAsFixed(0),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'AI Recommendations'),
          ...report.recommendations.map((r) => pw.Bullet(text: r)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'OORJA_Energy_Report_${report.generatedAt.day}_${report.generatedAt.month}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}