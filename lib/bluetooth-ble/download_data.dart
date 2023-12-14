import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/scan_screen.dart';
import 'utils/extra.dart';

// import 'bluetoothListPage.dart';
import 'upload_listview.dart';

class DownLoadData extends StatefulWidget {
  final String pathFolder;
  const DownLoadData({Key? key, required this.pathFolder}) : super(key: key);

  @override
  State<DownLoadData> createState() => _DownLoadDataState();
}

class _DownLoadDataState extends State<DownLoadData> {
  // bluetooth
  // final bleManage = FlutterBluePlus.instance;
  late StreamSubscription<BluetoothAdapterState> connectionState;
  BluetoothCharacteristic? bluetoothcharacteristics;

  TextEditingController dateinputFrom = TextEditingController();
  TextEditingController dateinputTo = TextEditingController();
  late ApplicationDate appDate;

  //Command
  List<int> bufferData = []; // Lưu dữ liệu trả về
  late AppCmd appCmd;

  //State
  late ApplicationState appState;
  int limitRecord = 0;

  @override
  void initState() {
    super.initState();
    DateTime date = DateTime.now();
    DateTime dateWithOutTime = DateTime(date.year, date.month, date.day);
    DateTime yesterday = dateWithOutTime.subtract(const Duration(days: 1));

    appDate = ApplicationDate(
        current: dateWithOutTime,
        yesterday: yesterday,
        selectDateFrom: yesterday,
        selectDateTo: yesterday);

    dateinputFrom.text =
        dateinputTo.text = DateFormat('dd-MM-yyyy').format(appDate.yesterday);

    appState = ApplicationState();
    appCmd = AppCmd();

    connectionState = FlutterBluePlus.adapterState.listen((event) {
      log('status: $event');
    });
  }

  Future<void> _showUploadPage() async {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => UpLoadFile(pathFolder: widget.pathFolder)),
    );
  }

  @override
  void dispose() {
    if (appState.connected) disconnect(appState.idDevice);
    appState.stop = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải dữ liệu từ bluetooth'),
        actions: [
          IconButton(
            onPressed: () {
              _showUploadPage();
            },
            icon: const Icon(Icons.list_outlined),
          ),
          iconBluetooth()
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Row(
              children: [
                getDateFrom(context),
                getDateTo(context),
                IconButton(
                    onPressed: () {
                      if (!appState.connected) {
                        return;
                      }

                      if (!appState.isProcessData) {
                        appState.isProcessData = true;
                        loopingSendCmd();
                      }
                    },
                    icon: const Icon(Icons.download))
              ],
            ),
            const Divider(
              height: 10,
              thickness: 1.5,
            ),
            Center(
              child: dataProcess(),
            ),
            Expanded(child: showProcessing()),
          ],
        ),
      ),
    );
  }

  void connect(BluetoothDevice deviceId) async {
    await deviceId.connect();
    await discoveredServiceList(deviceId);
    await deviceId.requestMtu(223);
    setState(() {});
  }

  Future<void> loopingSendCmd() async {
    downloadDataFromDevice();

    appState.timeRetry = 2000;
    bool fullCmdStep1 = false;
    bool haveDataStep1 = false;
    bool fullCmdStep2 = false;
    bool haveDataStep2 = false;
    int idx35 = 0;
    // log('${appState.stop}');

    while (!appState.stop) {
      if (appState.stop) {
        break;
      }

      idx35 = 0;
      // Xử lý dữ liệu lệnh 1
      if (appCmd.step == 1) {
        idx35 = isFullCmdMessege(bufferData);
        // Chưa đầy đủ lệnh, chờ gói tiếp theo
        if (idx35 >= 50 && bufferData.length - idx35 >= 2) {
          // log('bufferData step 1: idx35-$idx35 ; ${bufferData.length}\n$bufferData');
          fullCmdStep1 = true;
        }

        if (fullCmdStep1) {
          fullCmdStep1 = false;
          appCmd.cmdStep = bufferData.sublist(0, idx35 + 1);
          appCmd.parseCmdStep1 = readCmdStep1(appCmd.cmdStep);
          haveDataStep1 = true;
        }

        if (haveDataStep1) {
          haveDataStep1 = false;
          // Lệnh ngày không có dữ liệu, gửi lệnh ngày tiếp theo
          if (appCmd.parseCmdStep1 == null) {
            sendCommandDay(appCmd.totalCommanDay);
          } else {
            appCmd.step = 2;
            appState.needCmd = true;
            sendCommandInDay(appCmd.parseCmdStep1!.idx,
                appCmd.parseCmdStep1!.dayNo, appCmd.myCountCmdInDay);

            // SaveFile
            String saveNameFile =
                '${appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].fileDay}_${appCmd.parseCmdStep1!.id}_${appCmd.parseCmdStep1!.licensePlate}';

            File value = await createFileTemp();
            appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].temp = value;
            appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].fileName =
                '$saveNameFile.dat';
          }
        }
      }

      // Xử lý dữ liệu lệnh 2
      if (appCmd.step == 2) {
        if (appState.needCmd) {
          idx35 = isFullCmdMessege(bufferData);
          if (idx35 > 0) {
            fullCmdStep2 = true;
            appState.needCmd = false;
          }
        }

        if (fullCmdStep2) {
          fullCmdStep2 = false;
          appCmd.cmdStep = bufferData.sublist(0, idx35 + 1);
          // log('bufferData step 2: idx35-$idx35 ; ${bufferData.length}\n$bufferData');
          bufferData.removeRange(0, idx35 + 1);
          appCmd.parseCmdStep2 = readCmdStep2(appCmd.cmdStep);
          haveDataStep2 = true;
        }

        if (haveDataStep2) {
          // Nhận đầy đủ dữ liệu ở lệnh 2, gửi lệnh tiếp theo và lưu
          if (bufferData.length == appCmd.parseCmdStep2) {
            String data = '${hex.encode(bufferData)}\r\n';

            //Lưu dữ liệu
            await appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].temp
                .writeAsString(data, mode: FileMode.append);

            appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].fileSize +=
                data.length;

            appState.needCmd = true;
            haveDataStep2 = false;
            sendCommandInDay(appCmd.parseCmdStep1!.idx,
                appCmd.parseCmdStep1!.dayNo, appCmd.myCountCmdInDay);
          }

          bool breakNow = false;

          if (limitRecord > 0 && appCmd.myCountCmdInDay >= limitRecord) {
            breakNow = true;
          }

          // Lệnh 2 không có dữ liệu, gửi lệnh tiếp theo
          if (appCmd.parseCmdStep2 == 0 || breakNow) {
            // 5 lần lệnh liên tiếp không có dữ liệu, gửi lệnh ngày tiếp theo
            if (appCmd.myCountCmdEmpty >= appCmd.totalCommandEmpty ||
                breakNow) {
              log('nextCmdDay - ${bufferData.length}\n$bufferData');
              appState.needCmd = true;
              haveDataStep2 = false;
              appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].isDone = true;
              File value = await createFile(
                  appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].fileName);
              await appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].temp
                  .copy(value.path);
              await appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].temp
                  .delete();
              sendCommandDay(appCmd.totalCommanDay);
            } else {
              // log('dataCmdStep2 == 0: $myCountCmdEmpty - ${bufferData.length}');
              appState.needCmd = true;
              haveDataStep2 = false;
              sendCommandInDay(appCmd.parseCmdStep1!.idx,
                  appCmd.parseCmdStep1!.dayNo, appCmd.myCountCmdInDay);
              appCmd.myCountCmdEmpty++;
              log('myCountCmdEmpty: ${appCmd.myCountCmdEmpty}');
            }
          }
        }
      }

      appCmd.curTimeOnCmd = DateTime.now().millisecondsSinceEpoch;
      if (appCmd.curTimeOnCmd - appCmd.lastSentCommand >= appState.timeRetry) {
        if (appState.myCountRetryCmdDay >= appCmd.totalRetry) {
          log('TimeOut: ${appState.myCountRetryCmdDay}');
          break;
        }
        bluetoothcharacteristics!.sendPackage(appCmd.curCmd);
        log('Repeat SendDayCommand: ${appCmd.myCountCmdDay} - ${appCmd.curCmd}');
        appCmd.lastSentCommand = appCmd.curTimeOnCmd;
        appState.timeRetry += appState.timeRetry; //2mu(n)
        appState.myCountRetryCmdDay++;
      }

      await Future.delayed(const Duration(milliseconds: 1));
    }

    appState.isProcessData = false;
    appState.stop = false;
    appState.myCountRetryCmdDay = 0;
  }

  void disconnect(BluetoothDevice device) {
    device.disconnect();
    appState.connected = false;
    log('disconnect: ${device.name}');
  }

  void downloadDataFromDevice() async {
    if (!appState.connected) return;
    appCmd.myCountCmdDay = 0;
    bufferData.clear();
    appCmd.totalCommanDay = checkTotalDataCommand();
    sendCommandDay(appCmd.totalCommanDay);
  }

  void sendCommandDay(List<DatModel> command) {
    appCmd.lastSentCommand = DateTime.now().millisecondsSinceEpoch;
    appCmd.step = 1;
    bufferData.clear();
    if (appCmd.myCountCmdDay >= command.length) {
      appState.stop = true;
      appCmd.myCountCmdDay = -1;
      setState(() {});
      return;
    }

    appCmd.curCmd = command[appCmd.myCountCmdDay].cmd.codeUnits;
    bluetoothcharacteristics!.sendPackage(appCmd.curCmd);

    log('SendDayCommand: ${appCmd.myCountCmdDay} - ${command[appCmd.myCountCmdDay].cmd}');
    appCmd.myCountCmdDay++;
    appCmd.myCountCmdInDay = 0;
    appCmd.myCountCmdEmpty = 0;
  }

  bool sendCommandInDay(String idx, String dayNo, int countRecord) {
    appCmd.lastSentCommand = DateTime.now().millisecondsSinceEpoch;
    bufferData.clear();
    setState(() {});

    if (countRecord < appCmd.totalRealCommand ||
        appCmd.myCountCmdEmpty >= appCmd.totalCommandEmpty) {
      return true;
    }

    String headCommandInDay = '*SS,1,READ,1,2,';
    String tailCommand = '#';

    appCmd.curCmd =
        '$headCommandInDay$idx,$dayNo,$countRecord$tailCommand'.codeUnits;
    bluetoothcharacteristics!.sendPackage(appCmd.curCmd);
    log('SendCommandInDay: $headCommandInDay$idx,$dayNo,$countRecord$tailCommand - empty: ${appCmd.myCountCmdEmpty}');
    appCmd.myCountCmdInDay++;
    return false;
  }

  List<DatModel> checkTotalDataCommand() {
    List<DatModel> checkTotalDateCommand = [];
    String parseDateShow;
    String headCommand = '*SS,1,READ,1,1,';
    String tailCommand = '#';

    if (appDate.selectDateFrom == appDate.selectDateTo) {
      String data = DateFormat('yyyyMMdd').format(appDate.selectDateFrom);
      String command = headCommand + data + tailCommand;
      parseDateShow = DateFormat('dd-MM-yyyy').format(appDate.selectDateFrom);
      checkTotalDateCommand
          .add(DatModel(cmd: command, fileDay: data, showDay: parseDateShow));
    } else {
      var diff =
          appDate.selectDateTo.difference(appDate.selectDateFrom).inDays + 1;
      log('diff date: $diff');
      DateTime temp = appDate.selectDateFrom;
      for (var i = 0; i < diff; i++) {
        String data = DateFormat('yyyyMMdd').format(temp);
        String command = headCommand + data + tailCommand;
        parseDateShow = DateFormat('dd-MM-yyyy').format(temp);
        checkTotalDateCommand
            .add(DatModel(cmd: command, fileDay: data, showDay: parseDateShow));
        temp = temp.add(const Duration(days: 1));
      }
    }

    return checkTotalDateCommand;
  }

  Future<File> createFile(String fileName) async {
    File file = File(await getFilePath(fileName)); // 1
    file.writeAsString('', mode: FileMode.write); // 2
    return file;
  }

  Future<File> createFileTemp() async {
    var appDocDir = await getTemporaryDirectory();
    String path = '${appDocDir.path}/download.temp';
    File file = File(path); // 1
    file.writeAsString('', mode: FileMode.write); // 2
    return file;
  }

  Future<String> getFilePath(String fileName) async {
    Directory appDocumentsDirectory = Directory(widget.pathFolder); //1
    String appDocumentsPath = appDocumentsDirectory.path; // 2
    String filePath = '$appDocumentsPath/$fileName'; // 3
    return filePath;
  }

  void readFile(String fileName) async {
    File file = File(await getFilePath(fileName)); // 1
    String fileContent = await file.readAsString(); // 2

    log('File Content $fileName: $fileContent');
  }

  Text dataProcess() {
    String text = 'Chờ tải xuống';
    String connectDevice = 'Hãy kết nối bluetooth';

    if (!appState.connected) {
      text = connectDevice;
    } else if (appCmd.myCountCmdDay <= 0) {
      text = 'Chờ tải xuống';
    } else if (appCmd.totalCommanDay.isNotEmpty) {
      String dateProcess =
          appCmd.totalCommanDay[appCmd.myCountCmdDay - 1].showDay;
      text = 'Đang tải dữ liệu ngày: $dateProcess / ${appCmd.myCountCmdInDay}';
    }

    Text textShow =
        Text(text, textAlign: TextAlign.start, overflow: TextOverflow.fade);

    return textShow;
  }

  ListView showProcessing() {
    List<DatModel> showList = appCmd.totalCommanDay
        .where((element) => element.isDone == true)
        .toList();
    return ListView.builder(
        itemCount: showList.length,
        itemBuilder: (_, int index) {
          int size = (showList[index].fileSize / 1024).round();
          return ListTile(
            title: Text(showList[index].fileName),
            subtitle: size <= 0
                ? Text('${showList[index].fileSize}B')
                : Text('${size}KB'),
          );
        });
  }

  Expanded getDateFrom(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: dateinputFrom,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "From"),
          readOnly: true,
          onTap: () async {
            DateTime? pickedDateFrom = await showDatePicker(
                context: context,
                initialDate: appDate.yesterday,
                firstDate: DateTime(2000),
                lastDate: appDate.yesterday);

            pickedDateFrom ??= appDate.yesterday;
            appDate.selectDateFrom = pickedDateFrom;

            if (appDate.selectDateTo.isBefore(appDate.selectDateFrom)) {
              appDate.selectDateTo = appDate.selectDateFrom;
              dateinputTo.text =
                  DateFormat('dd-MM-yyyy').format(appDate.selectDateTo);
            }

            setState(() {
              dateinputFrom.text =
                  DateFormat('dd-MM-yyyy').format(appDate.selectDateFrom);
            });
          },
        ),
      ),
    );
  }

  Expanded getDateTo(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: dateinputTo, //editing controller of this TextField
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "To"),
          readOnly: true,
          onTap: () async {
            DateTime? pickedDateTo = await showDatePicker(
                context: context,
                initialDate: appDate.selectDateTo,
                firstDate: appDate.selectDateFrom,
                lastDate: appDate.current);

            pickedDateTo ??= appDate.yesterday;
            appDate.selectDateTo = pickedDateTo;

            setState(() {
              dateinputTo.text =
                  DateFormat('dd-MM-yyyy').format(appDate.selectDateTo);
            });
          },
        ),
      ),
    );
  }

  Future<void> discoveredServiceList(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services.last.characteristics;
    var blecharacteristics = characteristics.last;
    // log('befor: $bluetoothcharacteristics\n$blecharacteristics');
    if (bluetoothcharacteristics == null ||
        bluetoothcharacteristics!.deviceId != blecharacteristics.deviceId) {
      bluetoothcharacteristics = blecharacteristics;
      // log('after: $bluetoothcharacteristics\n$blecharacteristics');

      bluetoothcharacteristics!.value.listen((value) {
        bufferData.addAll(value);
        appCmd.lastSentCommand = DateTime.now().millisecondsSinceEpoch;
        // if (mounted) setState(() {});
        // log(value.toString());
      });
    }
    await bluetoothcharacteristics!.setNotifyValue(true);
    bluetoothcharacteristics!.sendPackage('*Hello#'.codeUnits);
    appState.connected = true;
    appState.stop = false;
  }

  int isFullCmdMessege(List<int> lists) {
    for (var i = 0; i < lists.length; i++) {
      if (lists[i] == 35) {
        return i;
      }
    }
    return 0;
  }

  ParseCmdStep1? readCmdStep1(List<int> result) {
    String decode = String.fromCharCodes(result);
    List<String> elmentList = decode.trim().split(',');

    log('parseCommandFist: $elmentList');

    String hasData = elmentList[6];
    if (hasData == '0') return null;

    String id = elmentList[1];
    String idx = elmentList[7];
    String dayNo = elmentList[8];

    int totalSize = int.parse(elmentList[9]);
    if (totalSize < appCmd.maxSize) {
      appCmd.totalRealCommand = totalSize;
    }

    String licensePlate = elmentList[10];
    if (licensePlate == '#') {
      licensePlate = 'EMPTY';
    } else {
      licensePlate = elmentList[10].split('#')[0];
    }

    // List<String> temp = [idx, dayNo, id, licensePlate];
    return ParseCmdStep1(
        id: id, idx: idx, dayNo: dayNo, licensePlate: licensePlate);
  }

  int readCmdStep2(List<int> result) {
    String decode = String.fromCharCodes(result);
    List<String> elmentList = decode.trim().split(',');

    // log('parseCommandSecond: $elmentList');

    String hasData = elmentList[6];
    if (hasData == '0') return 0;

    List<String> lenData = elmentList[7].split('#');

    int totalSize = int.parse(lenData[0]);

    return totalSize;
  }

  IconButton iconBluetooth() {
    return IconButton(
      icon: const Icon(
        Icons.bluetooth,
      ),
      onPressed: () async {
        if (!appState.actionbtnBluetooth) return;

        appState.actionbtnBluetooth = true;
        appState.stop = true;
        if (appState.connected) {
          disconnect(appState.idDevice);
        }
        appState.connected = false;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ScanScreen(
                        // bluePlus: bleManage,
                        updateItem: (deviceId) {
                      appState.idDevice = deviceId;
                      connect(deviceId);
                      appCmd.totalCommanDay.clear();
                      setState(() {});
                    })));
      },
    );
  }

  // Future<String> getDatFilePath() async {
  //   Directory path = await getApplicationDocumentsDirectory();
  //   String pathRoot = '${path.path}/SKYSOFT';
  //   return pathRoot;
  // }

  // IconButton iconUpload() {
  //   return IconButton(
  //       onPressed: () {
  //         Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) =>
  //                     UpLoadFile(pathFolder: pathRootFolder)));
  //       },
  //       icon: const Icon(Icons.upload_file));
  // }
}

class DatModel {
  late String cmd;
  late String showDay;
  late String fileDay;
  late String fileName;
  late int fileSize = 0;
  late File temp;
  bool isDone = false;

  DatModel({required this.cmd, required this.fileDay, required this.showDay});
}

class ParseCmdStep1 {
  late String id;
  late String idx;
  late String dayNo;
  late String licensePlate;
  ParseCmdStep1(
      {required this.id,
      required this.idx,
      required this.dayNo,
      required this.licensePlate});
}

class ApplicationDate {
  late DateTime current;
  late DateTime yesterday;
  late DateTime selectDateFrom;
  late DateTime selectDateTo;
  ApplicationDate(
      {required this.current,
      required this.yesterday,
      required this.selectDateFrom,
      required this.selectDateTo});
}

class ApplicationState {
  bool stop = false;
  bool isProcessData = false;
  bool connected = false;
  int timeRetry = 2000;
  bool actionbtnBluetooth = true;
  int myCountRetryCmdDay = 0;
  bool needCmd = true;
  late BluetoothDevice idDevice;

  void resetState() {
    stop = false;
    isProcessData = false;
    connected = false;
    timeRetry = 2000;
    actionbtnBluetooth = true;
    needCmd = true;
  }
}

class AppCmd {
  int maxSize = 8192; //số bản ghi tối đa
  int totalRealCommand = 0; // số bản ghi thực tế
  int totalCommandEmpty = 5; // Khi có 5 bản ghi trống sẽ kết thúc gửi lệnh
  int totalRetry = 3; // Số lần gửi lại tối đa
  int myCountCmdEmpty = 0; // Đếm số bản ghi trống
  int myCountCmdInDay = 0; // Đếm số lệnh đã gửi trong 1 ngày
  int myCountCmdDay = 0; // Đếm số ngày cần lấy dữ liệu
  int myCountRetryCmdDay = 0; // Đếm số lần gửi lại
  int step = 1; // Trạng thái lệnh
  int lastSentCommand = 0; //Thời gian gửi lần cuối cùng
  List<int> curCmd = []; // Lưu Cmd cuối cùng, gửi lại khi bị timeout
  ParseCmdStep1?
      parseCmdStep1; //Phân tích có dữ liệu hay không để gửi lệnh step 2 (null là không có dữ liệu)
  int parseCmdStep2 =
      0; //Phân tích có dữ liệu hay không (0 là không có dữ liệu)
  List<DatModel> totalCommanDay = []; // Tổng danh sách ngày cần lấy dữ liệu
  List<int> cmdStep = []; // Lưu đầy đủ lệnh trả về
  int curTimeOnCmd = 0; // Thời gian timeout để retry
}
