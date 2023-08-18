import 'package:atusum/models/report.dart';
import 'package:flutter/material.dart';

import '../config.dart';

class ReportViewerPage extends StatelessWidget {
  final Report report;
  const ReportViewerPage({Key key, this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Reporte"),
        backgroundColor: ColorPalette.primaryBase,
      ),
      backgroundColor: ColorPalette.background,
      body: ListView(
        children: [
          _reportDescription(context),
          const SizedBox(height: 10),
          _reportResponse(),
        ],
      ),
    );
  }

  Container _reportDescription(context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          report.imgName != null && report.imgName.isNotEmpty
              ? Image(
                  image: NetworkImage(
                    '${Config.url}public/reports/${report.imgName}',
                  ),
                  height: screenHeight * 0.5,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : null,
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formats.formatDate(report.date),
                  style: const TextStyle(
                      color: ColorPalette.secondaryText, fontSize: 16),
                ),
                Text(
                  "Autobus #${report.bus.number}",
                  style: const TextStyle(
                      color: ColorPalette.secondaryText, fontSize: 16),
                )
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              report.description,
              style: const TextStyle(
                fontSize: 20,
                color: ColorPalette.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _reportResponse() {
    if (report.response == null) return Container();
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  Formats.formatDate(report.response.date),
                  style: const TextStyle(
                      color: ColorPalette.secondaryText, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              report.response.text,
              style: const TextStyle(
                fontSize: 20,
                color: ColorPalette.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
