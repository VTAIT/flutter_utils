import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

// import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/bluetooth-printer-thermal/widget-printer.dart';
import 'package:image/image.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class BlueToothPrintESCPOS extends StatefulWidget {
  const BlueToothPrintESCPOS({super.key, required this.title});
  final String title;
  @override
  State<BlueToothPrintESCPOS> createState() => _BlueToothPrintESCPOSState();
}

class _BlueToothPrintESCPOSState extends State<BlueToothPrintESCPOS> {
  // PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  // List<PrinterBluetooth> _devices = [];
  // ScreenshotController controller = ScreenshotController();

  @override
  void initState() {
    super.initState();

    //   printerManager.scanResults.listen((devices) async {
    //     // print('UI: Devices found ${devices.length}');
    //     setState(() {
    //       _devices = devices;
    //     });
    //   });
  }

  // void _startScanDevices() {
  //   setState(() {
  //     _devices = [];
  //   });
  //   printerManager.startScan(Duration(seconds: 4));
  // }

  // void _stopScanDevices() {
  //   printerManager.stopScan();
  // }

  Future<List<int>> demoReceipt(
      PaperSize paper, CapabilityProfile profile) async {
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];

    // Print image
    // final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
    // final Uint8List imageBytes = data.buffer.asUint8List();
    // final Image? image = decodeImage(imageBytes);
    // bytes += ticket.image(image);

    bytes += ticket.text('GROCERYLY',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += ticket.text('889  Watson Lane',
        styles: PosStyles(align: PosAlign.center));
    bytes += ticket.text('New Braunfels, TX',
        styles: PosStyles(align: PosAlign.center));
    bytes += ticket.text('Tel: 830-221-1234',
        styles: PosStyles(align: PosAlign.center));
    bytes += ticket.text('Web: www.example.com',
        styles: PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += ticket.hr();
    bytes += ticket.row([
      PosColumn(text: 'Qty', width: 1),
      PosColumn(text: 'Item', width: 7),
      PosColumn(
          text: 'Price', width: 2, styles: PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'Total', width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += ticket.row([
      PosColumn(text: '2', width: 1),
      PosColumn(text: 'ONION RINGS', width: 7),
      PosColumn(
          text: '0.99', width: 2, styles: PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '1.98', width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += ticket.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'PIZZA', width: 7),
      PosColumn(
          text: '3.45', width: 2, styles: PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '3.45', width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += ticket.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'SPRING ROLLS', width: 7),
      PosColumn(
          text: '2.99', width: 2, styles: PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.99', width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += ticket.row([
      PosColumn(text: '3', width: 1),
      PosColumn(text: 'CRUNCHY STICKS', width: 7),
      PosColumn(
          text: '0.85', width: 2, styles: PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.55', width: 2, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += ticket.hr();

    bytes += ticket.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
      PosColumn(
          text: '\$10.97',
          width: 6,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
    ]);

    bytes += ticket.hr(ch: '=', linesAfter: 1);

    bytes += ticket.row([
      PosColumn(
          text: 'Cash',
          width: 7,
          styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$15.00',
          width: 5,
          styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);
    bytes += ticket.row([
      PosColumn(
          text: 'Change',
          width: 7,
          styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$4.03',
          width: 5,
          styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);

    bytes += ticket.feed(2);
    bytes += ticket.text('Thank you!',
        styles: PosStyles(align: PosAlign.center, bold: true));

    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy H:m');
    final String timestamp = formatter.format(now);
    bytes += ticket.text(timestamp,
        styles: PosStyles(align: PosAlign.center), linesAfter: 2);

    // Print QR Code from image
    // try {
    //   const String qrData = 'example.com';
    //   const double qrSize = 200;
    //   final uiImg = await QrPainter(
    //     data: qrData,
    //     version: QrVersions.auto,
    //     gapless: false,
    //   ).toImageData(qrSize);
    //   final dir = await getTemporaryDirectory();
    //   final pathName = '${dir.path}/qr_tmp.png';
    //   final qrFile = File(pathName);
    //   final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
    //   final img = decodeImage(imgFile.readAsBytesSync());

    //   bytes += ticket.image(img);
    // } catch (e) {
    //   print(e);
    // }

    // Print QR Code using native function
    // bytes += ticket.qrcode('example.com');

    ticket.feed(2);
    ticket.cut();
    return bytes;
  }

  // Future<List<int>> testTicket(
  //     PaperSize paper, CapabilityProfile profile, BuildContext key) async {
  //   final Generator generator = Generator(paper, profile);
  //   List<int> bytes = [];
  //   final Uint8List buf = await controller
  //       .captureFromWidget(buildTicketKitchen(), context: key, pixelRatio: 1);
  //   // final Uint8List? buf = await controller.capture(pixelRatio: 1);
  //   // Print image
  //   // Directory dir = await getApplicationDocumentsDirectory();
  //   // String? path = await controller.captureAndSave(dir.path, fileName: "temp.png");
  //   // final ByteData data = await rootBundle.load(path!);
  //   // final Uint8List buf = data.buffer.asUint8List();

  //   final Image image = decodeImage(buf)!;

  //   // Print image using alternative commands
  //   bytes += generator.image(image);
  //   // bytes += generator.imageRaster(image, imageFn: PosImageFn.graphics);
  //   // bytes += generator.feed(1);
  //   // bytes += generator.cut();
  //   return bytes;
  // }

  // void _testPrint(PrinterBluetooth printer, BuildContext key) async {
  //   printerManager.selectPrinter(printer);

  //   // TODO Don't forget to choose printer's paper
  //   const PaperSize paper = PaperSize.mm58;
  //   final profile = await CapabilityProfile.load();

  //   // TEST PRINT
  //   try {
  //     List<int> printTicket = await testTicket(paper, profile, key);
  //     log("Data: $printTicket");
  //     // final PosPrintResult res = await printerManager.printTicket(printTicket,
  //     //     queueSleepTimeMs: 5, chunkSizeBytes: 100);
  //     // print(res.msg);
  //   } catch (e) {
  //     print(e);
  //   }
  //   // DEMO RECEIPT
  //   // final PosPrintResult res =
  //   //     await printerManager.printTicket((await demoReceipt(paper, profile)));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container()
        //     ListView.builder(
        //         itemCount: _devices.length,
        //         itemBuilder: (BuildContext context, int index) {
        //           return InkWell(
        //             onTap: () => _testPrint(_devices[index], context),
        //             child: Column(
        //               children: <Widget>[
        //                 Container(
        //                   // height: 60,
        //                   padding: EdgeInsets.only(left: 10),
        //                   alignment: Alignment.centerLeft,
        //                   child: Row(
        //                     children: <Widget>[
        //                       Icon(Icons.print),
        //                       SizedBox(width: 10),
        //                       Expanded(
        //                         child: Column(
        //                           crossAxisAlignment: CrossAxisAlignment.start,
        //                           mainAxisAlignment: MainAxisAlignment.center,
        //                           children: <Widget>[
        //                             Text(_devices[index].name ?? ''),
        //                             Text(_devices[index].address!),
        //                             Text("${_devices[index].type}"),
        //                             Text(
        //                               'Click to print a test receipt',
        //                               style: TextStyle(color: Colors.grey[700]),
        //                             ),
        //                           ],
        //                         ),
        //                       )
        //                     ],
        //                   ),
        //                 ),
        //                 Divider(),
        //                 // Screenshot(
        //                 //   controller: controller,
        //                 //   child: buildTicketKitchen())
        //               ],
        //             ),
        //           );
        //         }),
        // floatingActionButton: StreamBuilder<bool>(
        //   stream: printerManager.isScanningStream,
        //   initialData: false,
        //   builder: (c, snapshot) {
        //     if (snapshot.data!) {
        //       return FloatingActionButton(
        //         child: Icon(Icons.stop),
        //         onPressed: _stopScanDevices,
        //         backgroundColor: Colors.red,
        //       );
        //     } else {
        //       return FloatingActionButton(
        //         child: Icon(Icons.search),
        //         onPressed: _startScanDevices,
        //       );
        //     }
        //   },
        // ),
        );
  }
}
