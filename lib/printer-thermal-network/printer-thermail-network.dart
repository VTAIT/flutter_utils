import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:image/image.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/widget-printer.dart';
import 'package:screenshot/screenshot.dart';

class PrinterThermalNetWorkScreen extends StatefulWidget {
  const PrinterThermalNetWorkScreen({super.key, required this.title});
  final String title;
  @override
  State<PrinterThermalNetWorkScreen> createState() =>
      _PrinterThermalNetWorkScreenState();
}

class _PrinterThermalNetWorkScreenState
    extends State<PrinterThermalNetWorkScreen> {
  ScreenshotController controller = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Screenshot(controller: controller, child: buildTicketKitchen()),
              ElevatedButton(
                  onPressed: () async {
                    final printer = PrinterNetworkManager('192.168.1.100');
                    PosPrintResult connect = await printer.connect();
                    if (connect == PosPrintResult.success) {
                      Uint8List buf = await controller.captureFromWidget(
                          buildTicketKitchen(),
                          pixelRatio: 1);
                      final Image image = decodeImage(buf)!;
                      final profile = await CapabilityProfile.load();
                      final generator = Generator(PaperSize.mm80, profile);

                      List<int> bytes = [];
                      bytes += generator.image(image);

                      PosPrintResult printing =
                          await printer.printTicket(bytes);

                      print(printing.msg);
                      printer.disconnect();
                    }
                  },
                  child: Text("Print ticket")),
            ],
          ),
        ],
      ),
    );
  }
}
