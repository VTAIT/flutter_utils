import 'dart:io';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';

class UpLoadFile extends StatefulWidget {
  final String pathFolder;
  const UpLoadFile({Key? key, required this.pathFolder}) : super(key: key);

  @override
  State<UpLoadFile> createState() => _UpLoadFileState();
}

class _UpLoadFileState extends State<UpLoadFile> {
  List<DatModel> listFile = []; // danh sách file
  bool selectedAll = false;

  void _listDatFiles() async {
    listFile.clear();
    Directory appDocumentsDirectory = Directory(widget.pathFolder); //1
    appDocumentsDirectory
        .list(recursive: true, followLinks: false)
        .listen((entity) async {
      File temp = File(entity.path);
      DatModel datModel = DatModel.fromFile(temp);
      int size = await temp.length();
      size = (size / 1024).round();
      datModel.fileSize = size;
      listFile.add(datModel);
    }).onDone(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _listDatFiles();
  }

  Future<void> _uploadFiles() async {
    // VehicleApiService service = VehicleApiService();
    // bool found = false;
    // for (DatModel datFile in listFile) {
    //   if (datFile.select) {
    //     found = true;
    //     try {
    //       String data = await datFile.file.readAsString();
    //       ActionResult result =
    //           await service.uploadDatFile(datFile.fileName!, data);
    //       if (result.errorMessage != '') {
    //         showToast(result.errorMessage);
    //         break;
    //       }
    //       datFile.file.delete();
    //     } catch (e) {}
    //   }
    // }

    // if (listFile.isEmpty) {
    //   showToast("Không có file để tải lên!");
    // } else if (!found) {
    //   showToast("Bạn phải chọn file để tải lên!");
    // } else {
    //   showToast("Đã tải dữ liệu thành công!");
    //   _listDatFiles();
    // }
  }

  Future<void> _confirmDelete() async {
    bool found = false;
    for (DatModel datFile in listFile) {
      if (datFile.select) {
        found = true;
        break;
      }
    }

    if (found) {
      if (await confirm(
        context,
        title: const Text('Xác nhận'),
        content: const Text('Bạn thực sự muốn xóa file?'),
        textOK: const Text('Yes'),
        textCancel: const Text('No'),
      )) {
        _deleteFiles();
      }
    } else {
      // showToast("Bạn phải chọn file cần xóa!");
    }
  }

  void _deleteFiles() {
    for (DatModel datFile in listFile) {
      if (datFile.select) {
        datFile.file.delete();
      }
    }
    _listDatFiles();
  }

  Padding _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Visibility(
            visible: true,
            child: Expanded(
              child: TextButton(
                onPressed: () => _uploadFiles(),
                child: const Text('Tải lên',
                    style: TextStyle(color: Colors.white)),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ))),
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: TextButton(
              onPressed: () => _confirmDelete(),
              child: Text(
                'Xóa file',
                style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    listFile.sort((a, b) => b.fileName!.compareTo(a.fileName!));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải dữ liệu lên hệ thống'),
        actions: [
          PopupMenuButton(
              onSelected: (bool value) {
                selectedAll = value;
                for (var i = 0; i < listFile.length; i++) {
                  listFile[i].select = value;
                }

                setState(() {});
              },
              itemBuilder: (_) => [
                    PopupMenuItem<bool>(
                      value: true,
                      child: Row(children: <Widget>[
                        Container(
                          width: 50,
                          child: Icon(
                            Icons.done_all_outlined,
                            color: Colors.black54,
                          ),
                        ),
                        Text('Chọn tất cả')
                      ]),
                    ),
                    PopupMenuItem<bool>(
                      value: false,
                      child: Row(children: <Widget>[
                        Container(
                          width: 50,
                          child: Icon(
                            Icons.check_box_outline_blank_outlined,
                            color: Colors.black54,
                          ),
                        ),
                        Text('Bỏ chọn tất cả')
                      ]),
                    )
                  ])
        ],
      ),
      body: Container(
        child: ListView.builder(
          itemCount: listFile.length,
          itemBuilder: (_, int idx) {
            return ActionView(
              name: listFile[idx].fileName!,
              size: listFile[idx].fileSize,
              selected: listFile[idx].select,
              onChangeItem: (bool v) {
                listFile[idx].select = v;
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _buildControls(),
    );
  }
}

// ignore: must_be_immutable
class ActionView extends StatefulWidget {
  final String name;
  final int size;
  bool selected;
  final Function(bool select)? onChangeItem;
  ActionView(
      {Key? key,
      required this.name,
      required this.size,
      required this.selected,
      required this.onChangeItem})
      : super(key: key);

  @override
  State<ActionView> createState() => _ActionViewState();
}

class _ActionViewState extends State<ActionView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: actionView(widget.selected),
      onTap: () {
        widget.selected = !widget.selected;
        if (widget.selected) {
          widget.onChangeItem?.call(true);
        } else {
          widget.onChangeItem?.call(false);
        }
        setState(() {});
      },
    );
  }

  ListTile actionView(bool selected) {
    return ListTile(
      title: Text(widget.name),
      subtitle: Text('${widget.size} KB'),
      trailing: selectView(selected),
    );
  }

  Icon selectView(bool select) {
    return select
        ? const Icon(Icons.check_box)
        : const Icon(Icons.check_box_outline_blank);
  }
}

class DatModel {
  File file;
  String? fileName;
  int fileSize = 0;
  bool select = false;

  DatModel({required this.file});

  factory DatModel.fromFile(File file) {
    DatModel response = DatModel(file: file);

    response.fileName = file.path.split('/').last;

    return response;
  }
}
