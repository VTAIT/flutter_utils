import 'package:flutter/material.dart';

Widget buildTicketKitchen(
    // String logID, int tableID, int folioID, List<OrderItemModel> orderList
    ) {
  // FolioModel folio = Global.offlineData.folioList
  //     .firstWhere((element) => element.folioID == folioID);
  // List<Widget> widgetList = [];
  // for (var element in orderList) {
  //   widgetList.add(Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           flex: 2,
  //           child: Text(
  //             element.productName,
  //             style: const TextStyle(fontSize: 16, color: Colors.black),
  //           ),
  //         ),
  //         Text(
  //           "SL: ${element.quantity.toInt()}",
  //           style: const TextStyle(fontSize: 16, color: Colors.black),
  //         ),
  //       ],
  //     ),
  //   ));
  // }
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 3),
      color: Colors.white,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("Bill 0000000",
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Bàn 00000001",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Phòng 0000001",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "24:24",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(
            color: Colors.black,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Số 1",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Text(
                    "SL: Số 2",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Số 1",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Text(
                    "SL: Số 2",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    ),
  );

  // return Container(
  //   width: 380,
  //   // height: 200,
  //   // color: Colors.white,
  //   decoration: BoxDecoration(
  //       border: Border.all(color: Colors.black, width: 1), color: Colors.white),
  //   child: Text(
  //     "ABC",
  //     style: TextStyle(color: Colors.black, fontSize: 20),
  //   ),
  // );
}
