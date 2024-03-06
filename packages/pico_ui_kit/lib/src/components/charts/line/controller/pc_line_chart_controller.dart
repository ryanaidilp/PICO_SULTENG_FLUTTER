import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/charts/data/pc_chart_event.dart';
import 'package:pico_ui_kit/src/components/charts/data/pc_chart_state.dart';

class PCLineChartController extends ChangeNotifier {
  PCChartEvent? event;
  late PCChartState _state;
  late List<double> data;
  PCChartState get state => _state;

  void updateState(PCChartState state) {
    event = PCChartEvent.changeState;
    _state = state;
    notifyListeners();
  }

  void changeData(List<double> data) {
    event = PCChartEvent.changeData;
    this.data = data;
    notifyListeners();
  }

  void appendData(double value) {
    event = PCChartEvent.appendData;
    data.add(value);
    notifyListeners();
  }

  void updateLastData(double value) {
    event = PCChartEvent.updateData;
    data.last = value;
    notifyListeners();
  }
}
