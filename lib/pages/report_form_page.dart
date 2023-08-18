import 'dart:io';
import 'package:atusum/config.dart';
import 'package:atusum/helpers/loader.helper.dart';
import 'package:atusum/models/bus.dart';
import 'package:atusum/models/report.dart';
import 'package:atusum/services/bus.service.dart';
import 'package:atusum/services/report.service.dart';
import 'package:atusum/services/service_locator.dart';
import 'package:atusum/services/snackbar.service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportFormPage extends StatefulWidget {
  final Report report;
  const ReportFormPage({Key key, this.report}) : super(key: key);

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  // ignore: unused_field
  final Report _report = Report();
  List<Bus> buses;
  String phoneUniqueIdentifier = "";
  final _formKey = GlobalKey<FormState>();
  final ReportService reportService = serviceLocator<ReportService>();

  final ticketNumberController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    ticketNumberController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    LoaderHelper.showLoader(context);

    var buses = await serviceLocator<BusService>().getAllBuses();
    buses.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
    setState(() {
      this.buses = buses;
    });
    Navigator.of(context).pop();
  }

  void _pickImage(ImageSource source) async {
    FocusManager.instance.primaryFocus.unfocus();
    XFile image = await ImagePicker()
        .pickImage(source: source, maxWidth: 600, imageQuality: 20);
    Navigator.of(context).pop();
    setState(() {
      if (image != null) {
        _report.pickedImage = File(image.path);
      } else {
        _report.pickedImage = null;
      }
    });
  }

  void _sendReport() async {
    _report.description = descriptionController.text;
    _report.ticketNumber = ticketNumberController.text;

    if (_report.description == null || _report.description.isEmpty) {
      serviceLocator<SnackBarService>().show("Llené la descripción", context);
      return;
    } else if (_report.busId == null || _report.busId.isEmpty) {
      serviceLocator<SnackBarService>()
          .show("Seleccione un autobus para hacer el reporte", context);
      return;
    }

    LoaderHelper.showLoader(context);
    try {
      bool success = await serviceLocator<ReportService>().sendReport(_report);
      Navigator.of(context).pop();

      if (success) {
        Navigator.of(context).pop("reload");
      } else {
        serviceLocator<SnackBarService>()
            .show("Ocurrio un error al enviar el reporte", context);
      }
    } catch (ex) {
      Navigator.of(context).pop();
      serviceLocator<SnackBarService>()
          .show("Ocurrio un error al enviar el reporte", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields = [
      ticketNumberTextField(),
      busDropDown(),
      descriptionTextArea(),
      imagePickerContainer()
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Reporte"),
        backgroundColor: ColorPalette.primaryBase,
      ),
      body: Form(
        key: _formKey,
        child: Container(
          height: double.infinity,
          color: ColorPalette.background,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: formFields.length,
            itemBuilder: (BuildContext context, int i) {
              return formFields[i];
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPalette.primaryBase,
        foregroundColor: Colors.white,
        child: const Icon(Icons.send),
        onPressed: () {
          _sendReport();
        },
      ),
    );
  }

  Container ticketNumberTextField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: ticketNumberController,
        minLines: 1,
        maxLines: 1,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: "# Boleto De Autobus",
          labelStyle: TextStyle(fontSize: 20),
        ),
        style: const TextStyle(
          fontSize: 20,
        ),
      ),
    );
  }

  Container busDropDown() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: DropdownSearch<Bus>(
        mode: Mode.DIALOG,
        showSearchBox: true,
        autoFocusSearchBox: true,
        searchBoxDecoration: const InputDecoration(label: Text("Buscar...")),
        dropdownSearchDecoration: const InputDecoration(
          labelStyle: TextStyle(fontSize: 20),
          border: UnderlineInputBorder(),
        ),
        popupItemBuilder: (BuildContext context, Bus b, bool a) =>
            busListTile(b),
        dropdownBuilder: (BuildContext context, Bus b, String v) => Text(
          v,
          style: const TextStyle(fontSize: 20),
        ),
        onChanged: (Bus b) {
          setState(() {
            _report.busId = b.id;
          });
        },
        items: buses,
        itemAsString: (Bus b) => b.number,
        label: "Autobus",
        hint: "Seleccione el autobus a reportar",
      ),
    );
  }

  Container descriptionTextArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: descriptionController,
        minLines: 5,
        maxLines: 10,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: "Describa lo sucedido",
          labelStyle: TextStyle(fontSize: 20),
        ),
        style: const TextStyle(
          fontSize: 20,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingrese una descripción';
          }
          return null;
        },
      ),
    );
  }

  Container busListTile(Bus bus) {
    if (bus == null) return Container();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.directions_bus,
              size: 45,
              color: Colors.orange,
            ),
            title: Text(bus.number),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Center imagePickerContainer() {
    if (_report.pickedImage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: MaterialButton(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: const [
                  Icon(
                    Icons.image,
                    size: 60,
                    color: ColorPalette.primaryText,
                  ),
                  Text("Agregar Imagen")
                ],
              ),
            ),
            onPressed: () {
              _showImageTypSelector();
            },
          ),
        ),
      );
    } else {
      return Center(
        child: Stack(
          children: [
            Image.file(
              _report.pickedImage,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            Positioned(
              top: 10,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                iconSize: 40,
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _report.pickedImage = null;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  _showImageTypSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () async {
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Cargar desde la galería'),
              onTap: () async {
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }
}
