import 'dart:convert';
import 'dart:io';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../providers/steps_provider.dart';
import '../providers/weight_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataService {
  static Map<String, dynamic> gatherAllUserData({
    required UserProvider userProvider,
    required WaterProvider waterProvider,
    required StepsProvider stepsProvider,
    required WeightProvider weightProvider,
  }) {
    return {
      'profile': userProvider.user.toJson(),
      'water': waterProvider.water.toJson(),
      'steps': stepsProvider.steps.toJson(),
      'weight_history': weightProvider.weights.map((w) => w.toJson()).toList(),
      'weight_target': weightProvider.targetWeight,
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  static String exportToJSON(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> exportToExcel(Map<String, dynamic> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Health Data'];

    // Profile
    sheet.appendRow([TextCellValue('THÔNG TIN CÁ NHÂN')]);
    sheet.appendRow(
        [TextCellValue('Tên'), TextCellValue(data['profile']['name'] ?? '')]);
    sheet.appendRow([
      TextCellValue('Email'),
      TextCellValue(data['profile']['email'] ?? '')
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Steps
    sheet.appendRow([TextCellValue('BƯỚC CHÂN')]);
    sheet.appendRow([
      TextCellValue('Tổng bước hôm nay'),
      IntCellValue(data['steps']['steps'] ?? 0)
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Water
    sheet.appendRow([TextCellValue('NƯỚC UỐNG')]);
    sheet.appendRow([
      TextCellValue('Đã uống (ly)'),
      IntCellValue(data['water']['cupsDrunk'] ?? 0)
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Weight
    sheet.appendRow([TextCellValue('CÂN NẶNG')]);
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Cân nặng (kg)'),
      TextCellValue('BMI')
    ]);
    for (var w in (data['weight_history'] as List)) {
      sheet.appendRow([
        TextCellValue(w['dateTime']?.toString().substring(0, 10) ?? ''),
        DoubleCellValue(w['currentWeight']?.toDouble() ?? 0.0),
        DoubleCellValue(w['bmi']?.toDouble() ?? 0.0)
      ]);
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/HealthData_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await Share.shareXFiles([XFile(filePath)],
          text: 'Dữ liệu sức khỏe của tôi (Excel)');
    }
  }

  static Future<void> exportToPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'BAO CAO SUC KHOE'),
              pw.Paragraph(text: 'Ngay xuat: ${data['export_date']}'),
              pw.SizedBox(height: 20),
              pw.Text('Ho ten: ${data['profile']['name']}'),
              pw.Text('Email: ${data['profile']['email']}'),
              pw.SizedBox(height: 20),
              pw.Text('Chi so hom nay:'),
              pw.Bullet(text: 'Buoc chan: ${data['steps']['steps']}'),
              pw.Bullet(text: 'Nuoc uong: ${data['water']['cupsDrunk']} ly'),
              pw.SizedBox(height: 20),
              pw.Text('Lich su can nang:'),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Ngay', 'Can nang (kg)', 'BMI'],
                  ...(data['weight_history'] as List).map((w) => [
                        w['dateTime']?.toString().substring(0, 10) ?? '',
                        w['currentWeight']?.toString() ?? '',
                        w['bmi']?.toStringAsFixed(1) ?? ''
                      ])
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/HealthData_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)],
        text: 'Dữ liệu sức khỏe của tôi (PDF)');
  }
}
