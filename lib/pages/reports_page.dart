import 'package:atusum/config.dart';
import 'package:atusum/helpers/confirmation.helper.dart';
import 'package:atusum/helpers/loader.helper.dart';
import 'package:atusum/models/report.dart';
import 'package:atusum/pages/report_form_page.dart';
import 'package:atusum/pages/report_viewer.dart';
import 'package:atusum/services/connectivity.service.dart';
import 'package:atusum/services/report.service.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Report> _reports = [];
  String phoneUniqueIdentifier = "";
  final ReportService reportService = serviceLocator<ReportService>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _getReports();
    });
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  void _getReports() async {
    LoaderHelper.showLoader(context);
    List<Report> reports = await reportService.getMyReports();
    setState(() {
      _reports = reports;
    });
    Navigator.of(context).pop();
    if (_reports.isEmpty) {
      _askForNewReport();
    }
  }

  void _askForNewReport() async {
    bool confirmed = await ConfirmationHelper.ask(
        context, "", "Desea realizar un reporte ahora?");

    if (confirmed) {
      _newReport();
    }
  }

  void _viewReport(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportViewerPage(report: report),
      ),
    );
  }

  void _newReport() async {
    if (!await serviceLocator<ConnectivityService>().isConnected()) {
      serviceLocator<SnackBarService>()
          .show("Es necesario tener conexión para hacer un reporte", context);
      return;
    }
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportFormPage(),
      ),
    );
    if (result is String && result == "reload") {
      _getReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        backgroundColor: ColorPalette.primaryBase,
      ),
      body: Container(
        color: ColorPalette.background,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 0),
          itemCount: _reports.length,
          itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(top: 8),
            key: ValueKey(i),
            child: _reportListTile(_reports[i]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add_box, color: ColorPalette.danger),
        onPressed: _newReport,
      ),
    );
  }

  Container _reportListTile(Report report) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: (report.response == null)
            ? const Icon(
                Icons.report,
                size: 45,
                color: ColorPalette.danger,
              )
            : const Icon(
                Icons.check,
                size: 45,
                color: ColorPalette.primaryBase,
              ),
        title: Text(Formats.formatDate(report.date)),
        subtitle: Text(report.description),
        trailing: ElevatedButton(
          child: const Text('Ver'),
          onPressed: () => _viewReport(report),
        ),
      ),
    );
  }
}
