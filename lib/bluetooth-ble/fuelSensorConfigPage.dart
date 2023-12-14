import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:skysoft/global.dart';
// import 'fuel_config/submit_table.dart';
import 'screens/scan_screen.dart';
import 'utils/extra.dart';
import 'utils/tabWidget.dart';

// import '../pages/offline/bluetoothListPage.dart';
// import '../pages/fuel_config/fuelConfigGlobal.dart';
// import '../pages/fuel_config/history_listview.dart';
import 'utils/string_utils.dart';

// ignore: must_be_immutable
class FuelSensorConfigPage extends TabWidget {
  FuelSensorConfigPage() : super(Icon(Icons.widgets_outlined), "Cấu hình");

  @override
  State<FuelSensorConfigPage> createState() => _FuelSensorConfigPageState();
}

class _FuelSensorConfigPageState extends State<FuelSensorConfigPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  /* control signals */
  int STX = 2; // Start of TeXt
  int EOT = 4; // End Of Transmission
  int ACK = 6; // Positive ACknowledgement
  int C = 67; // capital letter C

  /* sizes */
  int dataSize = 1024;
  int crcSize = 2;

  /* THE PACKET: 1029 bytes */
  /* header: 3 bytes */
  // STX
  int packetNumber = 0;
  int invertedPacketNumber = 255;

  late OilSensorModel oilSensor;
  double columnTableHeight = 50;
  final TextEditingController _textFieldController = TextEditingController();
  final TableInfomation _tableInfomation = TableInfomation();
  String oilAmountButtonText = "";
  bool inDebugMode = false;
  static bool isFimwareUpdating = false;
  String firmwareFileName = "";
  String firmwareFilePath = "";
  final ScrollController _scrollControllerListDongDau = ScrollController();
  int maxShow = 100;
  int updateStep = 0;
  Uint8List? bytes = null;
  late TabController _tabController;
  final TextEditingController _debugTextController = TextEditingController();
  String _debugText = "";
  List<int> _response = [];
  double _completePercent = 0;
  bool _pauseDebugLog = false;
  bool _newLoad = false;

  @override
  void initState() {
    super.initState();
    oilSensor = OilSensorModel();
    oilSensor.bluetoothState();

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
  }

  @override
  void dispose() {
    isFimwareUpdating = false;

    if (mounted) {
      oilSensor.bluetoothDisconnect();
    }

    super.dispose();
  }

  Widget listWidget() {
    return Row(
      children: const [Text('N'), Icon(Icons.remove)],
    );
  }

  Future<void> requestPermission() async {
    await [Permission.locationWhenInUse, Permission.bluetooth].request();
  }

  void updateIValueN() {
    String tmp = _tableInfomation.valueN;
    if (tmp.contains(".")) {
      tmp = tmp.substring(0, tmp.indexOf("."));
    }
    try {
      if (inDebugMode) {
        _tableInfomation.iValueN = int.parse(tmp);
      } else {
        _tableInfomation.iValueN = int.parse(tmp, radix: 16);
      }
    } catch (e) {
      _tableInfomation.iValueN = -1;
    }
  }

  void updateIValueCN() {
    String tmp = _tableInfomation.valueCN;
    if (tmp.contains(".")) {
      tmp = tmp.substring(0, tmp.indexOf("."));
    }
    try {
      if (inDebugMode) {
        _tableInfomation.iValueCN = int.parse(tmp);
      } else {
        _tableInfomation.iValueCN = int.parse(tmp, radix: 16);
      }
    } catch (e) {
      _tableInfomation.iValueCN = -1;
    }
  }

  double getPercent(String value) {
    try {
      if (_tableInfomation.iValueCN >= 0) {
        return _tableInfomation.iValueCN / 1023;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _showBluetoothScanPage() async {
    await requestPermission();

    oilSensor.stop = true;
    if (oilSensor.idDevice != null) {
      await oilSensor.bluetoothDisconnect();
      oilSensor.idDevice = null;
    }

    if (!oilSensor.bluetoothOn) {
      // showSnackBar(context, 'Hãy bật bluetooth');
      return;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanScreen(updateItem: (deviceId) {
            oilSensor.connect(deviceId).then((value) {
              if (value) {
                loopingProcessData();
              }
            });
          }),
        ));
  }

  void _showHistory() {
    // _showDialog(
    //     "Nạp firmware thành công!\r\nCảm biến sẽ khởi động lại, chờ trong 10s trước khi cấu hình.");

    // Navigator.push(
    //     context, MaterialPageRoute(builder: (context) => const HistoryList()));
  }

  void loopingProcessData() async {
    oilSensor.stop = false;
    //oilSensor.cmdDebugOn();
    while (!oilSensor.stop) {
      if (oilSensor.queue.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      List<int> temp = oilSensor.queue.removeFirst();

      //print("_doUpdateFirmware: temp: ${tmp}");
      _response.addAll(temp);

      while (_response.length > 1024) {
        _response.removeAt(0);
      }

      if (!_pauseDebugLog) {
        try {
          //String tmp = nvl(utf8.decode(temp));
          String tmp = nvl(String.fromCharCodes(temp));
          appendDebugLog(tmp);
        } catch (e) {}
      }

      oilSensor.bufferData.addAll(temp);
      if (temp.contains(13) || temp.contains(10)) {
        oilSensor.fullCmd = true;
      }

      if (oilSensor.fullCmd) {
        oilSensor.fullCmd = false;
        try {
          String data = nvl(String.fromCharCodes(oilSensor.bufferData));

          if (data.contains("CN=")) {
            if (data.contains("step=")) {
              inDebugMode = true;
            } else {
              inDebugMode = false;
              if (!isFimwareUpdating) {
                // oilSensor.cmdDebugOn();
              }
            }
          }

          List<String> removeSpace = data.split(' ');
          for (var field in removeSpace) {
            List<String> removeEqual = field.split('=');
            switch (removeEqual.first) {
              case 'F':
                _tableInfomation.valueF = removeEqual.last;
                break;
              case 'FU':
                _tableInfomation.valueFU = removeEqual.last;
                break;
              case 'EM':
                _tableInfomation.valueEM = removeEqual.last;
                break;
              case 'CN':
                {
                  _tableInfomation.valueCN = removeEqual.last;
                  updateIValueCN();
                }
                break;
              case 'N':
                {
                  _tableInfomation.valueN = removeEqual.last;
                  updateIValueN();
                }
                break;
              case 'V':
                {
                  _tableInfomation.versionNo = removeEqual.last;
                }
                break;
              default:
                break;
            }
          }
          if (oilSensor.historyLog) {
            int len = oilSensor.showLogList.length;
            if (len >= maxShow) oilSensor.showLogList.removeLast();
            oilSensor.showLogList.insert(0, data);
          }
          oilSensor.bufferData.clear();
          setState(() {});
        } catch (e) {
          oilSensor.bufferData.clear();
        }
      }
    }
    oilSensor.bufferData.clear();
    oilSensor.queue.clear();
    // log('Kết thúc vòng lặp');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình cảm biến dầu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bluetooth,
            ),
            onPressed: () {
              _showBluetoothScanPage();
            },
          )
        ],
      ),
      body: new Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 1.0, color: Colors.lightBlueAccent))),
              child: TabBar(
                labelColor: Theme.of(context).primaryColor,
                controller: _tabController,
                tabs: [
                  Tab(
                    text: "Cấu hình",
                  ),
                  Tab(
                    text: "Nạp firmware",
                  ),
                ],
              ),
            ),
            Expanded(
                child: TabBarView(controller: _tabController, children: [
              _buildFuelConfigTab(),
              _buildUpdateFirmwareTab(),
            ]))
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 16,
      ),
    );
  }

  Padding _buildBottomFunctions(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: PopupMenuButton(
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 40),
                  elevation: 2,
                  onSelected: (result) {
                    _addSelectedValueToTable(result.toString());
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "10", child: Text("10")),
                    const PopupMenuItem(
                      value: "20",
                      child: Text("20"),
                    ),
                    const PopupMenuItem(
                      value: "30",
                      child: Text("30"),
                    ),
                    const PopupMenuItem(
                      value: "40",
                      child: Text("40"),
                    ),
                    const PopupMenuItem(
                      value: "50",
                      child: Text("50"),
                    ),
                    const PopupMenuItem(value: "", child: Text("Khác")),
                  ],
                  child: OutlinedButton.icon(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColor),
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.candlestick_chart),
                      label: const Text("Mức đong")),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: OutlinedButton.icon(
                    onPressed: () {
                      _addSelectedValueToTable(oilAmountButtonText);
                    },
                    icon: const Icon(Icons.add_chart),
                    label: Text(oilAmountButtonText)),
              ),
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _confirmClear(context);
                    },
                    label: const Text('Xoá hết'),
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: ElevatedButton(
                      onPressed: () {
                        _doSendData();
                      },
                      child: const Text('GỬI')),
                ),
              )
            ],
          )
        ]));
  }

  void _addSelectedValueToTable(String value) async {
    String? input = await _displayTextInputDialog(context, inputInitial: value);

    addValueTable(input ?? '');
  }

  void _showDialog(String text) async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("ĐÓNG LẠI"))
              ],
            ));
  }

  Future<void> _doOpenFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final path = result.files.first; // path file update
    if (path.path != null) {
      firmwareFilePath = path.path!;
      setState(() {
        firmwareFileName =
            firmwareFilePath.substring(firmwareFilePath.lastIndexOf("/") + 1);
      });
    }
    dev.log(path.path!);
  }

  Future<void> _doUpdateFirmware(bool newLoad) async {
    _newLoad = newLoad;
    if (firmwareFilePath == "") {
      // showToast("Bạn cần chọn file firmware để nạp");
      return;
    }

    setState(() {
      isFimwareUpdating = !isFimwareUpdating;
    });

    if (isFimwareUpdating) {
      try {
        File file = new File(firmwareFilePath);
        bytes = await file.readAsBytes();
        dev.log("_doUpdateFirmware: fileLen: ${bytes!.length}");
      } catch (e) {}

      if (bytes == null) {
        // showToast("Invalid file");
        return;
      }

      setState(() {
        _pauseDebugLog = false;
      });

      updateStep = 0;
      packetNumber = 0;
      invertedPacketNumber = 255;
      clearDebugLog();
      bool sentD = false;
      setState(() {
        _completePercent = 0;
      });
      Future.doWhile(() async {
        // dataProcessingBusy = true;
        String response = nvl(String.fromCharCodes(_response));
        //print("_doUpdateFirmware, step: ${updateStep}");
        if (updateStep == 0) {
          if (sentD && response.contains("C")) {
            updateStep++;
          } else {
            _response.clear();
            bool ok = await oilSensor.sendData('{{D}}'.codeUnits);
            if (!ok) {
              setState(() {
                isFimwareUpdating = false;
              });

              _showDialog(
                  "Nạp file bị lỗi, cần khởi động lại thiết bị bluetooth và thực hiện lại!");
            }
            sentD = true;
          }
        } else if (updateStep == 1) {
          _response.clear();
          bool ok = await sendYmodemInitialPacket();
          if (!ok) {
            setState(() {
              isFimwareUpdating = false;
            });

            _showDialog(
                "Nạp file bị lỗi, cần khởi động lại thiết bị bluetooth và thực hiện lại!");
          } else {
            ok = await waitForResponse(ACK, 5);
            if (!ok) {
              setState(() {
                isFimwareUpdating = false;
              });
              // showToast("Nạp file bị lỗi!");
            } else {
              updateStep++;
            }
          }
        } else if (updateStep == 2) {
          bool ok = false;
          if (_newLoad) {
            ok = await sendDataFileNew(bytes!);
          } else {
            ok = await sendDataFile(bytes!);
          }
          updateStep++;
          setState(() {
            isFimwareUpdating = false;
          });
          if (ok) {
            _showDialog(
                "Nạp firmware thành công!\r\nCảm biến sẽ khởi động lại, chờ trong 10s trước khi cấu hình.");
          }
        }

        await Future.delayed((Duration(milliseconds: 100)));
        if (!isFimwareUpdating) {
          // dataProcessingBusy = false;
        }
        return isFimwareUpdating;
      });
    }
  }

  Widget _buildUpdateFirmwareTab() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
                child: TextField(
              toolbarOptions: ToolbarOptions(
                  copy: true, paste: false, cut: false, selectAll: true
                  //by default all are disabled 'false'
                  ),
              controller: _debugTextController,
              maxLines: 30, //or null
              enabled: false,
              focusNode: FocusNode(),
            )),
            SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _pauseDebugLog = !_pauseDebugLog;
                      });
                    },
                    child: Text(
                      (_pauseDebugLog ? 'Bật Debug' : 'Tắt Debug'),
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.blue),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ))),
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      clearDebugLog();
                    },
                    child: const Text(
                      'Xóa Log',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.blue),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ))),
                  ),
                )
              ],
            ),
            Row(children: [
              Expanded(
                  child: Container(
                height: 40,
                decoration: BoxDecoration(color: Colors.grey),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    firmwareFileName.isNotEmpty
                        ? firmwareFileName
                        : "Chưa chọn file",
                  ),
                ),
              )),
              SizedBox(
                width: 8,
              ),
              Container(
                width: 80,
                child: TextButton(
                  onPressed: () {
                    _doOpenFile();
                  },
                  child: const Text(
                    'OPEN',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ))),
                ),
              ),
              SizedBox(
                width: 6,
              )
            ]),
            Row(children: [
              Expanded(
                  child: Container(
                height: 40,
                decoration: BoxDecoration(color: Colors.grey),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LinearProgressIndicator(
                    minHeight: 40,
                    value: _completePercent,
                  ),
                ),
              )),
              SizedBox(
                width: 8,
              ),
              Container(
                width: 80,
                child: TextButton(
                  onPressed: () {
                    if (isFimwareUpdating) {
                      setState(() {
                        isFimwareUpdating = !isFimwareUpdating;
                      });
                    } else {
                      _showActionMenu();
                    }
                  },
                  child: const Text(
                    'NẠP',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          isFimwareUpdating ? Colors.green : Colors.blue),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ))),
                ),
              ),
              SizedBox(
                width: 6,
              )
            ]),
          ],
        ),
      ),
    );
  }

  void _showActionMenu() {
    FocusScope.of(context).requestFocus(new FocusNode());

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (context) {
          return Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.file_upload_outlined),
                title: Text('Nạp theo kiểu mới TPR'),
                onTap: () {
                  Navigator.of(context).pop();
                  _doUpdateFirmware(true);
                },
              ),
              ListTile(
                leading: Icon(Icons.child_care_outlined),
                title: Text('Nạp kiểu cũ - Bluetooth chưa update'),
                onTap: () {
                  Navigator.of(context).pop();
                  _doUpdateFirmware(false);
                },
              ),
              const Divider(
                color: Colors.grey,
                thickness: 0.2,
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined),
                title: Text('Bỏ qua'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Center _buildFuelConfigTab() {
    return Center(
        child: Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(width: 1),
                              top: BorderSide(width: 1),
                              bottom: BorderSide(width: 1))),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'F = ${_tableInfomation.valueF}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(left: BorderSide(width: 1))),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'FU = ${_tableInfomation.valueFU}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(width: 1),
                              top: BorderSide(width: 1),
                              bottom: BorderSide(width: 1))),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'EM = ${_tableInfomation.valueEM}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                        alignment: Alignment.center,
                        child: Text(
                          "CN",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ))
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'CN = ${_tableInfomation.iValueCN}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(width: 1),
                              right: BorderSide(width: 1))),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'N = ${_tableInfomation.iValueN}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          border: Border(
                        top: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      )),
                      child: SizedBox(
                        height: columnTableHeight,
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'V = ${_tableInfomation.versionNo}',
                              textAlign: TextAlign.center,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: SizedBox(
                        height: columnTableHeight * 3,
                        width: 50,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: LinearProgressIndicator(
                            value: _tableInfomation.valueN == 'N/A'
                                ? 0
                                : getPercent(_tableInfomation.valueN),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                        alignment: Alignment.center,
                        child: Text(
                          "${_tableInfomation.iValueCN}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ))
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  _confirmSetFull();
                },
                child: const Text(
                  'FULL',
                  style: TextStyle(color: Colors.white),
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ))),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  _confirmSetEmpty();
                },
                child: const Text(
                  'EMPTY',
                  style: TextStyle(color: Colors.white),
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ))),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  _showHistory();
                },
                child: const Text(
                  "LỊCH SỬ",
                  style: TextStyle(color: Colors.white),
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ))),
              ),
            ),
            SizedBox(
              width: 8,
            ),
          ],
        ),
        const Divider(
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: const [
                    Expanded(
                        flex: 1,
                        child: Text('Lít Đong', textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child:
                            Text('Tổng số lít', textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text('Giá trị CN', textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Expanded(flex: 1, child: Text('')),
            ],
          ),
        ),
        const Divider(
          thickness: 1,
        ),
        Expanded(child: Container()
            // ListView.builder(
            //     controller: _scrollControllerListDongDau,
            //     itemCount: oilSensor.dongDauList.length,
            //     itemBuilder: (context, index) {
            //       return Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 20),
            //         child: Row(
            //           children: [
            //             Expanded(
            //               flex: 4,
            //               child: Row(
            //                 children: [
            //                   Expanded(
            //                       flex: 1,
            //                       child: Text(
            //                           '${oilSensor.dongDauList[index].litDong}',
            //                           textAlign: TextAlign.center)),
            //                   Expanded(
            //                       flex: 1,
            //                       child: Text(
            //                           '${oilSensor.dongDauList[index].tongSoLit}',
            //                           textAlign: TextAlign.center)),
            //                   Expanded(
            //                       flex: 1,
            //                       child: Text(
            //                           '${oilSensor.dongDauList[index].giaTriN}',
            //                           textAlign: TextAlign.center)),
            //                 ],
            //               ),
            //             ),
            //             Expanded(
            //                 child: IconButton(
            //                     // sửa lít đong ở đây
            //                     onPressed: () {
            //                       _showEditDialog(
            //                           index, oilSensor.dongDauList[index]);
            //                     },
            //                     icon: const Icon(Icons.edit)))
            //           ],
            //         ),
            //       );
            //     }),
            ),
        _buildBottomFunctions(context),
      ],
    ));
  }

  // Future<void> _showEditDialog(int index, DongDauModel model) async {
  //   String? value = await _displayTextInputDialog(context,
  //       inputInitial: '${model.litDong}');
  //   updateValueTable(value ?? '', index, oilSensor.dongDauList);
  // }

  // void _showDebugLog() {
  //   oilSensor.historyLog = true;
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => LogOilSensor(
  //               oilSensorModel: oilSensor,
  //               callBack: (result) => oilSensor.historyLog = result),
  //           fullscreenDialog: true));
  // }

  void _doSendData() {
    // if (!oilSensor.onPressLast(
    //     context, DateTime.now().millisecondsSinceEpoch)) {
    //   return;
    // }

    // if (oilSensor.dongDauList.isEmpty) {
    //   // showSnackBar(context, 'Bạn cần có dữ liệu đong dầu');
    //   return;
    // }

    // oilSensor.infoAdd.dongDauList = oilSensor.dongDauList;
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => SubmitTable(
    //             infomationSave: oilSensor.infoAdd,
    //             resultCallBack: (isDone) async {
    //               if (isDone) {
    //                 oilSensor.listInfoSave = await oilSensor.loadDataBase();
    //                 oilSensor.listInfoSave.add(oilSensor.infoAdd);
    //                 oilSensor.storage.write(
    //                     key: FuelConfigGlobal.dataBase,
    //                     value:
    //                         oilSensor._encoder.convert(oilSensor.listInfoSave));
    //                 await Clipboard.setData(
    //                     ClipboardData(text: oilSensor.getInfoCopy()));

    //                 setState(() {
    //                   oilSensor.infoAdd = InfomationSave();
    //                   oilSensor.dongDauList.clear();
    //                   oilSensor.totalValue = 0;
    //                   showSnackBar(context, 'Đã lưu và sao chép thông tin');
    //                 });
    //               }
    //             },
    //             isReadOnly: false),
    //         fullscreenDialog: true));
  }

  void _doSetEmpty() {
    // if (!oilSensor.onPressLast(
    //     context, DateTime.now().millisecondsSinceEpoch)) {
    //   return;
    // }

    // oilSensor.cmdSetEmpty().then((value) {
    //   String tmp = 'Set EMPTY thành công';
    //   if (!value) {
    //     tmp = 'Set EMPTY không thành công\nHãy chắc chắn đã kết nối bluetooth';
    //   }
    //   // showSnackBar(context, tmp);
    // });
  }

  void _confirmSetFull() async {
    if (await confirm(
      context,
      title: const Text('Xác nhận'),
      content: const Text('Xác nhận gửi lệnh SET FULL?'),
      textOK: const Text('OK'),
      textCancel: const Text('Bỏ qua'),
    )) {
      _doSetFull();
    }
  }

  void _confirmSetEmpty() async {
    if (await confirm(
      context,
      title: const Text('Xác nhận'),
      content: const Text('Xác nhận gửi lệnh SET EMPTY?'),
      textOK: const Text('OK'),
      textCancel: const Text('Bỏ qua'),
    )) {
      _doSetEmpty();
    }
  }

  void _doSetFull() {
    // if (!oilSensor.onPressLast(
    //     context, DateTime.now().millisecondsSinceEpoch)) {
    //   return;
    // }

    // oilSensor.cmdSetFull().then((value) {
    //   String tmp = 'Set FULL thành công';
    //   if (!value) {
    //     tmp = 'Set FULL không thành công\nHãy chắc chắn đã kết nối bluetooth';
    //   }
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       content: Text(
    //         tmp,
    //         style: const TextStyle(color: Colors.black),
    //       ),
    //       duration: const Duration(seconds: 3),
    //       backgroundColor: Colors.grey));
    // });
  }

  Future<void> _confirmClear(BuildContext context) async {
    // if (await confirm(
    //   context,
    //   title: const Text('Xác nhận'),
    //   content: const Text('Xác nhận xóa tất cả giá trị?'),
    //   textOK: const Text('OK'),
    //   textCancel: const Text('Bỏ qua'),
    // )) {
    //   String text = oilSensor.dongDauList.isEmpty
    //       ? 'Không có giá trị nào để xóa'
    //       : 'Xóa giá trị thành công';
    //   // showSnackBar(context, text);

    //   setState(() {
    //     oilSensor.dongDauList.clear();
    //     oilSensor.totalValue = 0;
    //   });
    // }
  }

  Future<String?> _displayTextInputDialog(BuildContext context,
      {String inputInitial = ''}) async {
    _textFieldController.text = inputInitial;
    late BuildContext dialogContext;
    var value = await showDialog<String>(
        context: context,
        builder: (context) {
          dialogContext = context;
          return AlertDialog(
            title: const Text('Nhập giá trị đong dầu'),
            content: TextField(
              keyboardType: TextInputType.numberWithOptions(
                  decimal: false, signed: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  try {
                    final text = newValue.text;
                    if (text.isNotEmpty) int.parse(text);
                    return newValue;
                  } catch (e) {}
                  return oldValue;
                }),
              ],
              onChanged: (value) {
                inputInitial = value;
              },
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "Ví dụ: 40"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(inputInitial);
                },
              )
            ],
          );
        });
    return value;
  }

  void addValueTable(String value) {
    // log('Value: $value');
    // if (value == "") return;
    // if (!oilSensor.isConnected) {
    //   // showSnackBar(context, 'Hãy kết nối bluetooth');
    //   return;
    // }

    // int valueN = _tableInfomation.iValueCN;

    // if (valueN < 0) {
    //   // showToast("Giá trị N phải >= 0");
    //   return;
    // }

    // setState(() {
    //   try {
    //     double temp = double.parse(value);
    //     oilAmountButtonText = temp.toInt().toString();
    //     oilSensor.totalValue += temp.toInt();

    //     oilSensor.dongDauList.add(DongDauModel(
    //         litDong: temp.toInt(),
    //         tongSoLit: oilSensor.totalValue.toInt(),
    //         giaTriN: valueN));
    //   } catch (e) {}
    // });

    // _scrollControllerListDongDau.animateTo(
    //     _scrollControllerListDongDau.position.maxScrollExtent +
    //         MediaQuery.of(context).size.height * 0.06,
    //     duration: const Duration(milliseconds: 200),
    //     curve: Curves.easeOut);
  }

  // void updateValueTable(String newValue, int index, List<DongDauModel> lists) {
  // if (newValue == "") return;

  // int newV = 0;
  // try {
  //   newV = int.parse(newValue);
  // } catch (e) {
  //   // showSnackBar(context, 'Giá trị không hợp lệ!');
  // }

  // int oldV = lists[index].litDong;

  // if (newV == oldV || newV <= 0) {
  //   // showSnackBar(
  //   //     context, 'Giá trị đong dầu phải lớn hơn 0 hoặc khác giá trị cũ');
  //   return;
  // }

  // lists[index].litDong = newV;

  // int temp = 0;
  // for (var i = 0; i < lists.length; i++) {
  //   temp += lists[i].litDong;
  //   lists[i].tongSoLit = temp;
  // }

  // oilSensor.totalValue = lists.last.tongSoLit;
  // setState(() {});
  // }

  Future<bool> sendYmodemInitialPacket() async {
    String name = "firmware.bin";

    String fileSize = bytes!.length.toString();
    List<int> initData = List.filled(dataSize, 0, growable: false);

    int count = 0;
    /* add filename to data */
    for (int value in name.codeUnits) {
      initData[count++] = value;
    }
    initData[count++] = 0;

    /* add filesize to data */
    for (int value in fileSize.codeUnits) {
      initData[count++] = value;
    }

    /* send the packet */
    if (_newLoad) {
      return await sendYmodemPacketNew(initData);
    } else {
      return await sendYmodemPacket(initData);
    }

    //log('sendYmodemInitialPacket Done');
  }

  void appendDebugLog(String data) {
    _debugText += data;

    if (_debugText.length > 512) {
      _debugText = _debugText.substring(_debugText.length - 512);
    }

    _debugTextController.text = _debugText;
    // _scrollContoller.animateTo(_scrollContoller.position.maxScrollExtent,
    //     duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  void clearDebugLog() {
    _debugText = "";
    _debugTextController.text = _debugText;
    // _scrollContoller.animateTo(0.0,
    //     duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  Future<bool> sendYmodemPacket(List<int> data) async {
    /* calculate CRC */
    List<int> CRC = calculateXModemCRC(data);

    List<int> sendData = [];
    sendData.addAll([STX, packetNumber, invertedPacketNumber]);
    sendData.addAll(data);
    sendData.addAll(CRC);
    dev.log(
        '_doUpdateFirmware, sendYmodemPacket: $packetNumber - $invertedPacketNumber - ${data.length} - ${CRC.length} - ${sendData.length}');

    List<int> sendPacket = [];
    int count = 0;
    for (var i = 0; i < sendData.length; i++) {
      sendPacket.add(sendData[i]);
      count++;
      if (count == 64) {
        List<int> package = makePackage(sendPacket);
        bool result = await oilSensor.sendData(package);
        if (!result) {
          return false;
        }
        sendPacket.clear();
        count = 0;
      }
    }

    if (sendPacket.isNotEmpty) {
      List<int> package = makePackage(sendPacket);
      return await oilSensor.sendData(package);
    }

    return true;
  }

  Future<bool> sendYmodemPacketNew(List<int> data) async {
    /* calculate CRC */
    List<int> CRC = calculateXModemCRC(data);

    String cmd = "*SS,123,TPR,12,1,${packetNumber},1029#";
    // await oilSensor.sendData(cmd.codeUnits);

    List<int> sendData = [];
    sendData.addAll(cmd.codeUnits);
    sendData.addAll([STX, packetNumber, invertedPacketNumber]);
    sendData.addAll(data);
    sendData.addAll(CRC);
    dev.log(
        '_doUpdateFirmware, sendYmodemPacketNew: $packetNumber - $invertedPacketNumber - ${data.length} - ${CRC.length} - ${sendData.length}');

    //send command first
    // String cmd = "*SS,123,TPR,12,1,${packetNumber},${sendData.length}#";
    // await oilSensor.sendData(cmd.codeUnits);

    //now send data
    List<int> sendPacket = [];
    int count = 0;
    for (var i = 0; i < sendData.length; i++) {
      sendPacket.add(sendData[i]);
      count++;
      if (count == 70) {
        // List<int> package = makePackage(sendPacket);
        bool result = await oilSensor.sendData(sendPacket);
        if (!result) {
          return false;
        }
        sendPacket.clear();
        count = 0;
      }
    }

    if (sendPacket.isNotEmpty) {
      // List<int> package = makePackage(sendPacket);
      return await oilSensor.sendData(sendPacket);
    }

    return true;
  }

  List<int> makePackage(List<int> input) {
    List<int> package = [];
    package.addAll("{{".codeUnits);
    package.addAll(input);
    package.addAll("}}".codeUnits);
    return package;
  }

  Future<bool> sendDataFile(List<int> data) async {
    List<int> sendPacket = [];
    int count = 0;
    int allByteSend = 0;
    int totalPackage = (data.length / dataSize).round();
    if (data.length % dataSize != 0) {
      totalPackage++;
    }
    int sendingPacket = 0;
    for (var i = 0; i < data.length && isFimwareUpdating; i++) {
      sendPacket.add(data[i]);
      count++;

      if (count == dataSize) {
        allByteSend += count;

        packetNumber++;
        if (packetNumber > 255) {
          packetNumber -= 256;
        }
        /* calculate invertedPacketNumber */
        invertedPacketNumber = 255 - packetNumber;

        /* send the packet */
        _response.clear();
        await sendYmodemPacket(sendPacket);
        if (!isFimwareUpdating) {
          return false;
        }
        sendingPacket++;
        setState(() {
          _completePercent = (sendingPacket / totalPackage);
        });

        dev.log(
            '_doUpdateFirmware, Send Done packet $packetNumber - $allByteSend');
        //var result = HEX.encode(sendPacket);
        //log('_doUpdateFirmware, hex: ${result}');

        sendPacket.clear();
        count = 0;

        bool ok = await waitForResponse(ACK, 5);
        if (!ok) {
          setState(() {
            isFimwareUpdating = false;
          });
          // showToast("Nạp file không thành công!");
          return false;
        }
      }
    }

    if (sendPacket.isNotEmpty) {
      if (!isFimwareUpdating) {
        return false;
      }

      packetNumber++;
      if (packetNumber > 255) {
        packetNumber -= 256;
      }
      invertedPacketNumber = 255 - packetNumber;

      while (sendPacket.length < dataSize) {
        sendPacket.add(0);
      }
      allByteSend += sendPacket.length;

      dev.log(
          '_doUpdateFirmware, Send Done remainPacket $packetNumber - $allByteSend');
      _response.clear();
      await sendYmodemPacket(sendPacket);
      sendingPacket++;
      setState(() {
        _completePercent = (sendingPacket / totalPackage);
      });

      bool ok = await waitForResponse(ACK, 5);
      if (!ok) {
        setState(() {
          isFimwareUpdating = false;
        });
        // showToast("Nạp file không thành công!");
        return false;
      }

      dev.log(
          '_doUpdateFirmware, sendDataFile end done $packetNumber - $allByteSend');

      //send EOT
      List<int> eotPacket = [];
      eotPacket.addAll("{{".codeUnits);
      eotPacket.add(EOT);
      eotPacket.addAll("}}".codeUnits);
      await oilSensor.sendData(eotPacket);
      dev.log('_doUpdateFirmware send EOT done');

      packetNumber = 0;
      invertedPacketNumber = 255;
      List<int> closingPacket = List.filled(dataSize, 0);

      /* send the packet */
      await sendYmodemPacket(closingPacket);
      dev.log('_doUpdateFirmware send closingPacket done');
      clearDebugLog();

      ok = await waitForResponse(ACK, 5);
      if (!ok) {
        setState(() {
          isFimwareUpdating = false;
        });
        // showToast("Nạp file không thành công!");
        return false;
      } else {
        return true;
      }
    }

    return false;
  }

  Future<bool> sendDataFileNew(List<int> data) async {
    List<int> sendPacket = [];
    int count = 0;
    int allByteSend = 0;
    int totalPackage = (data.length / dataSize).round();
    if (data.length % dataSize != 0) {
      totalPackage++;
    }
    int sendingPacket = 0;
    for (var i = 0; i < data.length && isFimwareUpdating; i++) {
      sendPacket.add(data[i]);
      count++;

      if (count == dataSize) {
        allByteSend += count;

        packetNumber++;
        if (packetNumber > 255) {
          packetNumber -= 256;
        }
        /* calculate invertedPacketNumber */
        invertedPacketNumber = 255 - packetNumber;

        /* send the packet */
        _response.clear();
        await sendYmodemPacketNew(sendPacket);
        if (!isFimwareUpdating) {
          return false;
        }
        sendingPacket++;
        setState(() {
          _completePercent = (sendingPacket / totalPackage);
        });

        dev.log(
            '_doUpdateFirmware, New Send Done packet $packetNumber - $allByteSend - sent: ${sendingPacket}/${totalPackage}');
        //var result = HEX.encode(sendPacket);
        //log('_doUpdateFirmware, hex: ${result}');

        sendPacket.clear();
        count = 0;

        bool ok = await waitForResponse(ACK, 5);
        if (!ok) {
          setState(() {
            isFimwareUpdating = false;
          });
          // showToast("Nạp file không thành công!");
          dev.log(
              '_doUpdateFirmware,sendDataFileNew Error $packetNumber - $allByteSend - sent: ${sendingPacket}/${totalPackage}');
          return false;
        }
      }
    }

    if (sendPacket.isNotEmpty) {
      if (!isFimwareUpdating) {
        return false;
      }

      packetNumber++;
      if (packetNumber > 255) {
        packetNumber -= 256;
      }
      invertedPacketNumber = 255 - packetNumber;

      while (sendPacket.length < dataSize) {
        sendPacket.add(0);
      }
      allByteSend += sendPacket.length;

      dev.log(
          '_doUpdateFirmware, Send Done remainPacket $packetNumber - $allByteSend');
      _response.clear();
      await sendYmodemPacketNew(sendPacket);
      sendingPacket++;
      setState(() {
        _completePercent = (sendingPacket / totalPackage);
      });

      bool ok = await waitForResponse(ACK, 5);
      if (!ok) {
        setState(() {
          isFimwareUpdating = false;
        });
        // showToast("Nạp file không thành công!");
        return false;
      }

      dev.log(
          '_doUpdateFirmware, sendDataFile end done $packetNumber - $allByteSend');

      //send EOT
      List<int> eotPacket = [];
      eotPacket.addAll("{{".codeUnits);
      eotPacket.add(EOT);
      eotPacket.addAll("}}".codeUnits);
      // await oilSensor.sendData(eotPacket);
      dev.log('_doUpdateFirmware send EOT done');

      packetNumber = 0;
      invertedPacketNumber = 255;
      List<int> closingPacket = List.filled(dataSize, 0);

      /* send the packet */
      await sendYmodemPacketNew(closingPacket);
      dev.log('_doUpdateFirmware send closingPacket done');
      clearDebugLog();

      ok = await waitForResponse(ACK, 5);
      if (!ok) {
        setState(() {
          isFimwareUpdating = false;
        });
        // showToast("Nạp file không thành công!");
        return false;
      } else {
        return true;
      }
    }

    return false;
  }

  Future<bool> waitForResponse(int check, int timeout) async {
    int end = DateTime.now().millisecondsSinceEpoch + (timeout * 1000);
    while (DateTime.now().millisecondsSinceEpoch < end) {
      if (_response.contains(check)) {
        return true;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }

    return false;
  }

//Sử dụng hàm này để tính tính crc16ccitt
// Đọc data từ file ở dạng hex, gui theo hex
  List<int> calculateXModemCRC(List<int> args) {
    int polynomial = 0x1021; // Represents x^16+x^12+x^5+1
    int crc = 0x0000;
    for (int i = 0; i < args.length; ++i) {
      int b = args[i];
      for (int i = 0; i < 8; i++) {
        bool bit = ((b >> (7 - i) & 1) == 1);
        bool c15 = ((crc >> 15 & 1) == 1);
        crc <<= 1;
        // If coefficient of bit and remainder polynomial = 1 xor crc
        // with polynomial
        if (c15 ^ bit) crc ^= polynomial;
      }
    }

    crc &= 0xffff;
    // log('crc: $crc');
    var byteData = ByteData(2)..setInt16(0, crc, Endian.big); // big or little
    Uint8List crcS = byteData.buffer.asUint8List();
    //tính lại kết quả để so sánh
    // crc = (crcS[0] << 8) | crcS[1];
    // log(byteData.buffer.asUint8List().toString());
    // log('crc after: $crc');
    return crcS;
  }
}

class OilSensorModel {
  // List<DongDauModel> dongDauList = [];
  // InfomationSave infoAdd = InfomationSave();
  // List<InfomationSave> listInfoSave = [];
  int totalValue = 0;
  bool historyLog = false;

  //bluetooth
  //final bleManage = FlutterBluePlus.instance;
  // BluetoothCharacteristic? bluetoothcharacteristics;
  BluetoothDevice? idDevice;
  bool isConnected = false;
  bool bluetoothOn = false;
  List<int> bufferData = [];
  List<String> showLogList = [];

  //process data
  String stringDebugOn = '{{*SS,123456789,DEBUG,112233,1#}}';
  String stringDebugOff = '{{*SS,123456789,DEBUG,112233,0#}}';
  String stringSetFull = '{{*SS,123456789,SF,112233,1#}}';
  String stringSetEmpty = '{{*SS,123456789,SE,112233,1#}}';
  Queue<List<int>> queue = Queue<List<int>>();
  List<int> queueData = [];
  bool stop = false;
  bool fullCmd = false;
  final JsonEncoder _encoder = const JsonEncoder();
  final JsonDecoder _decoder = const JsonDecoder();
  final storage = const FlutterSecureStorage();
  StreamSubscription<List<int>>? listenerHolder = null;
  BluetoothCharacteristic? bluetoothcharacteristics = null;
  StreamSubscription<BluetoothAdapterState>? connectionState;

  // late StreamSubscription<BluetoothAdapterState>

  // bool checkBaudRate = true;
  // List<int> baudRateOriginal = [
  //   79,
  //   75,
  //   43,
  //   71,
  //   101,
  //   116,
  //   58,
  //   49
  // ]; // check baudrate
  int timeOnPress = 0;
  bool isShowToast = true;

  void bluetoothState() {
    connectionState = FlutterBluePlus.adapterState.listen((event) {
      // log('status bluetooth: $event');
      if (event == BluetoothAdapterState.off) {
        bluetoothOn = false;
        if (isConnected) {
          bluetoothDisconnect();
        }
      } else if (event == BluetoothAdapterState.on) {
        bluetoothOn = true;
      }
    });
  }

  Future<void> bluetoothDisconnect() async {
    listenerHolder?.cancel();

    listenerHolder = null;

    await idDevice?.disconnect();

    isConnected = false;
  }

  // Future<List<InfomationSave>> loadDataBase() async {
  // final String? json = await storage.read(key: FuelConfigGlobal.dataBase);
  // if (json != null) {
  //   dynamic listDatabase = _decoder.convert(json);
  //   return (listDatabase as List)
  //       .map((e) => InfomationSave.fromJson(e))
  //       .toList();
  // } else {
  //   return [];
  // }
  //   return [];
  // }

  Future<void> discoveredServiceList(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services.last.characteristics;
    var blecharacteristics = characteristics.last;

    if (listenerHolder == null ||
        bluetoothcharacteristics == null ||
        bluetoothcharacteristics!.remoteId != blecharacteristics.remoteId) {
      bluetoothcharacteristics = blecharacteristics;

      listenerHolder?.cancel();

      listenerHolder =
          bluetoothcharacteristics!.lastValueStream.listen((value) {
        queue.add(value);
        queueData.addAll(value);
      });
    }

    await bluetoothcharacteristics?.setNotifyValue(true);
  }

  Future<bool> connect(BluetoothDevice deviceId) async {
    isConnected = false;
    try {
      await deviceId.connectAndUpdateStream();
      await deviceId.requestMtu(223);
      await discoveredServiceList(deviceId);
    } on Exception catch (e) {
      dev.log('connect: ${e.toString()}');
      return isConnected;
    }
    idDevice = deviceId;
    isConnected = true;
    return isConnected;
  }

  // _sendPackage(List<int> package) async {
  //   if (package.length <= 20) {
  //     print("Sending small package");
  //     await bluetoothcharacteristics?.write(package);
  //   } else {
  //     print("Sending chunked package of ${package.length} bytes");

  //     int chunk = 0;
  //     int nextRemaining = package.length;
  //     List<int> toSend;

  //     while (nextRemaining > 0) {
  //       toSend = package.sublist(chunk, chunk + min(20, nextRemaining));
  //       print("Enviando chunk $toSend");
  //       await _sendPackage(toSend);
  //       await Future.delayed(Duration(milliseconds: 20));
  //       nextRemaining -= 20;
  //       chunk += 20;
  //     }
  //   }
  // }

//   Future<bool> cmdDebugOn() async {
//     await bluetoothcharacteristics?.sendPackage(stringDebugOn.codeUnits);
//     return true;
//   }

  Future<bool> sendData(List<int> data) async {
    try {
      await bluetoothcharacteristics?.sendPackage(data);
    } catch (e) {
      dev.log("Error sendData: $e");
      return false;
    }
    return true;
  }

//   // Future<bool> cmdDebugOff() async {
//   //   if (bluetoothcharacteristics == null) {
//   //     // log('cmdDebugOff error: bluetoothcharacteristics null');
//   //     return false;
//   //   }
//   //   await _sendPackage(stringDebugOff.codeUnits);
//   //   return true;
//   // }

//   Future<bool> cmdSetFull() async {
//     await bluetoothcharacteristics?.sendPackage(stringSetFull.codeUnits);
//     return true;
//   }

//   Future<bool> cmdSetEmpty() async {
//     await bluetoothcharacteristics?.sendPackage(stringSetEmpty.codeUnits);
//     return true;
//   }

//   bool onPressLast(BuildContext context, int currentTime) {
//     if (currentTime - timeOnPress <= 5000) {
//       if (!isShowToast) {
//         isShowToast = true;
//         // showSnackBar(context, 'Bạn thao tác quá nhanh');
//       }
//       return false;
//     }

//     timeOnPress = currentTime;
//     isShowToast = false;
//     return true;
//   }

//   String getInfoCopy() {
//     String dataCopy = 'Khách hàng: ${infoAdd.guestController}\n'
//         'Biển số: ${infoAdd.licenseController}\n'
//         'Chiều dài: ${infoAdd.lengthController}\n'
//         'Chiều rộng: ${infoAdd.widthController}\n'
//         'Chiều cao: ${infoAdd.heightController}\n'
//         'Sau cắt: ${infoAdd.afterCutController}\n'
//         'Ghi chú: ${infoAdd.commentController}\n'
//         '\nChỉ số đong dầu:\n';
//     for (var value in infoAdd.dongDauList!) {
//       dataCopy += '${value.giaTriN};${value.tongSoLit}\n';
//     }
//     return dataCopy;
//   }
}

// class DongDauModel {
//   int litDong = 0;
//   int tongSoLit = 0;
//   int giaTriN = 0;
//   DongDauModel(
//       {required this.litDong, required this.tongSoLit, required this.giaTriN});

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> dongDauSave = {
//       FuelConfigGlobal.giaTriN: giaTriN,
//       FuelConfigGlobal.tongSoLit: tongSoLit,
//     };
//     return dongDauSave;
//   }

//   factory DongDauModel.fromJson(Map<String, dynamic> json) {
//     DongDauModel model = DongDauModel(
//       litDong: 0,
//       giaTriN: json[FuelConfigGlobal.giaTriN],
//       tongSoLit: json[FuelConfigGlobal.tongSoLit],
//     );
//     return model;
//   }
// }

class TableInfomation {
  String valueF = 'N/A';
  String valueFU = 'N/A';
  String valueEM = 'N/A';
  String valueCN = 'N/A';
  String versionNo = 'N/A';
  int iValueCN = -1;
  String valueN = 'N/A';
  int iValueN = -1;
}

// class InfomationSave {
//   String? guestController;
//   String? licenseController;
//   String? lengthController;
//   String? widthController;
//   String? heightController;
//   String? afterCutController;
//   String? commentController;
//   List<DongDauModel>? dongDauList;

//   InfomationSave({
//     this.guestController,
//     this.licenseController,
//     this.lengthController,
//     this.widthController,
//     this.heightController,
//     this.afterCutController,
//     this.commentController,
//   });

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> infoSave = {
//       FuelConfigGlobal.guestController: guestController,
//       FuelConfigGlobal.licenseController: licenseController,
//       FuelConfigGlobal.lengthController: lengthController,
//       FuelConfigGlobal.widthController: widthController,
//       FuelConfigGlobal.heightController: heightController,
//       FuelConfigGlobal.afterCutController: afterCutController,
//       FuelConfigGlobal.commentController: commentController,
//       FuelConfigGlobal.dongDauList: dongDauList,
//     };
//     return infoSave;
//   }

//   factory InfomationSave.fromJson(Map<String, dynamic> json) {
//     InfomationSave model = InfomationSave(
//       guestController: json[FuelConfigGlobal.guestController],
//       licenseController: json[FuelConfigGlobal.licenseController] ?? "",
//       lengthController: json[FuelConfigGlobal.lengthController] ?? "",
//       widthController: json[FuelConfigGlobal.widthController] ?? "",
//       heightController: json[FuelConfigGlobal.heightController] ?? "",
//       afterCutController: json[FuelConfigGlobal.afterCutController] ?? "",
//       commentController: json[FuelConfigGlobal.commentController] ?? "",
//     );
//     var listDongDau = json[FuelConfigGlobal.dongDauList];
//     model.dongDauList =
//         (listDongDau as List).map((e) => DongDauModel.fromJson(e)).toList();
//     return model;
//   }
// }
