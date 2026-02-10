import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/data/repositories/report_repository.dart';
import 'package:kreatif_laundry_offline_app/core/services/export_service.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/report/report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ExportService _exportService;

  ReportCubit({
    ReportRepository? reportRepository,
    ExportService? exportService,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        _exportService = exportService ?? ExportService(),
        super(const ReportInitial());

  /// Load report data
  Future<void> loadReport(DateTime startDate, DateTime endDate) async {
    emit(const ReportLoading());

    try {
      final data = await _reportRepository.getReportData(startDate, endDate);
      final orders =
          await _reportRepository.getOrdersByDateRange(startDate, endDate);

      emit(ReportLoaded(data: data, orders: orders));
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Export report to Excel
  Future<void> exportToExcel() async {
    final currentState = state;
    if (currentState is! ReportLoaded) return;

    emit(const ReportExporting());

    try {
      final filePath = await _exportService.exportOrdersToExcel(
        currentState.orders,
        currentState.data,
      );

      // Share the file
      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan berhasil di-export',
      ));

      // Restore previous state
      emit(currentState);
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }
}
