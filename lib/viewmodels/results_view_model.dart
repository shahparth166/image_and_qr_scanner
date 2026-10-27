import 'package:get/get.dart';

import '../models/capture_item.dart';

enum ResultsFilter { all, qr, barcode, none }

class ResultsViewModel extends GetxController {
  ResultsViewModel(this.items);

  final List<CaptureItem> items;
  ResultsFilter selectedFilter = ResultsFilter.all;

  bool matches(CaptureItem item, ResultsFilter filter) {
    switch (filter) {
      case ResultsFilter.all:
        return true;
      case ResultsFilter.qr:
        return item.hasQr;
      case ResultsFilter.barcode:
        return item.hasBarcode;
      case ResultsFilter.none:
        return !item.hasCode;
    }
  }

  int count(ResultsFilter filter) =>
      items.where((item) => matches(item, filter)).length;

  String label(ResultsFilter filter) {
    switch (filter) {
      case ResultsFilter.all:
        return 'All';
      case ResultsFilter.qr:
        return 'QR';
      case ResultsFilter.barcode:
        return 'Barcode';
      case ResultsFilter.none:
        return 'No code';
    }
  }

  void selectFilter(ResultsFilter filter) {
    selectedFilter = filter;
    update();
  }
}
