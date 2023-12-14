import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const String asciiCharform =
    "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYDAAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz"; //extra

const String unicodeCharform =
    "àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž";

const String dateTimeFormat = "dd/MM/yyyy HH:mm:ss";
const String dateFormat = "dd/MM/yyyy";
const String timeFormat = "HH:mm:ss";
const String tzDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ssZZ";

String nvl(String? input) {
  return input ?? "";
}

String formatBytes({required int bytes, int decimals = 0}) {
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${((bytes / pow(1024, i)).toStringAsFixed(decimals))} ${suffixes[i]}';
}

extension RemoveAccentsOnString on String {
  // static const diacritics =
  //     'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  // static const nonDiacritics =
  //     'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  String get removeAccents => splitMapJoin('',
      onNonMatch: (char) => char.isNotEmpty && unicodeCharform.contains(char)
          ? asciiCharform[unicodeCharform.indexOf(char)]
          : char);
}

extension KeepDigitsLetters on String {
  String get keepDigitsLetters => replaceAll("[^a-zA-Z0-9- ]", "");
}

extension KeepLetters on String {
  //String get keepLetters => this.replaceAll("[^a-zA-Z0-9]", "");
  String get keepLetters =>
      replaceAll("-", "").replaceAll(".", "").replaceAll("_", "");
}

extension SearchText on String {
  String get searchText => this
      .replaceAll("-", "")
      .replaceAll(".", "")
      .replaceAll("_", "")
      .removeAccents
      .toLowerCase();
}

extension ParseUTC on String {
  //String get keepLetters => this.replaceAll("[^a-zA-Z0-9]", "");
  DateTime? get parseUTC =>
      nvl(this).isEmpty ? null : DateFormat(tzDateTimeFormat).parseUTC(this);
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

ThemeMode getInitialTheme(String? value) {
  switch (value) {
    case "system":
      return ThemeMode.system;
    case "light":
      return ThemeMode.light;
    case "dark":
      return ThemeMode.dark;
  }
  return ThemeMode.system;
}
