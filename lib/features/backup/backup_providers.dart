import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database_provider.dart';
import 'export_service.dart';
import 'import_service.dart';
import 'pdf_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(appDatabaseProvider));
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.watch(appDatabaseProvider));
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService(ref.watch(appDatabaseProvider));
});
