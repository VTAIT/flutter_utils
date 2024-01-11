import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildCaptainOrder(
    // String logID, int tableID, int folioID, List<OrderItemModel> orderList
    {int countBill = 0}) {
  // FolioModel folio = Global.offlineData.folioList
  //     .firstWhere((element) => element.folioID == folioID);
  // String counterName = "";
  // for (var restaurant in Global.loginResponse.restaurants) {
  //   for (var counter in restaurant.counterList) {
  //     if (orderList.first.counterID == counter.counterID) {
  //       counterName = counter.name;
  //       break;
  //     }
  //   }
  // }
  double fontSizeTitle = 20;

  List<Widget> widgetList = [];

  for (int i = 0; i < 10; i++) {
    widgetList.add(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              "$i Name: 00000000000",
              style: TextStyle(
                fontSize: fontSizeTitle,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    widgetList.add(Text(".......................................",
        style: TextStyle(fontSize: fontSizeTitle, color: Colors.black)));
  }

  return Container(
    width: 360,
    padding: const EdgeInsets.only(top: 35, bottom: 50),
    child: Container(
      decoration:
          BoxDecoration(border: Border.all(color: Colors.black, width: 3)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.black, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 5),
                    decoration: const BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.black, width: 1))),
                    child: Text(
                      "BAR",
                      style: TextStyle(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Text(
                    "Bàn A1 - ${DateFormat("HH:mm").format(DateTime.now())}",
                    style: TextStyle(
                        fontSize: fontSizeTitle,
                        // fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "R.No: $countBill",
                      style: TextStyle(
                          fontSize: fontSizeTitle, color: Colors.black),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "jsdlfksdljkf_",
                      style: TextStyle(
                          fontSize: fontSizeTitle, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Divider(
              color: Colors.black,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgetList,
            ),
          ),
        ],
      ),
    ),
  );
}
