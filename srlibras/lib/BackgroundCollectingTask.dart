import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

class DataSample {
  double temperature1;
  double temperature2;
  double waterpHlevel;
  DateTime timestamp;

  DataSample({this.temperature1, this.temperature2, this.waterpHlevel, this.timestamp});
}

class BackgroundCollectingTask extends Model
{
  static BackgroundCollectingTask of(BuildContext context, {bool rebuildOnChange = false}) =>
      ScopedModel.of<BackgroundCollectingTask>(context, rebuildOnChange: rebuildOnChange);
  
  final BluetoothConnection _connection;
  List<int> _buffer = List<int>();

  // @TODO , Such sample collection in real code should be delegated 
  // (via `Stream<DataSample>` preferably) and then saved for later
  // displaying on chart (or even stright prepare for displaying).
  var samples = List<DataSample>(); // @TODO ? should be shrinked at some point, endless colleting data would cause memory shortage.
  
  var simpleSamples = List<int>(); 
  int num_elements = 0;
  bool inProgress;

  BackgroundCollectingTask._fromConnection(this._connection) {
    final first_time = DateTime.now();
    _connection.input.listen((data) {
      for(int i=0; i<data.length; i++){
        simpleSamples.add(data[i]);
      }
      if(simpleSamples.length == 30){
        print(simpleSamples);
        final cur_time = DateTime.now();
        print("time: " + cur_time.difference(first_time).inMilliseconds.toString() + " ms.");
        notifyListeners();
      }
    }).onDone(() {
      inProgress = false;
      notifyListeners();
    });
  }

  static Future<BackgroundCollectingTask> connect(BluetoothDevice server) async {
    final BluetoothConnection connection = await BluetoothConnection.toAddress(server.address);
    return BackgroundCollectingTask._fromConnection(connection);
  }

  BluetoothConnection getConnection(){
    return this._connection;
  }

  Future<Uint8List> getData(){
    _connection.input.listen((data) {
      for(int i=0; i<data.length; i++){
        simpleSamples.add(data[i]);
      }
      if(simpleSamples.length == 30){
        print(simpleSamples);
        notifyListeners();
      }
    }).onDone(() {
      inProgress = false;
      notifyListeners();
    });
  }

  void dispose() {
    _connection.dispose();
  }

  Future<void> start() async {
    inProgress = true;
    _buffer.clear();
    samples.clear();
    notifyListeners();
    _connection.output.add(ascii.encode('a'));
    await _connection.output.allSent;
  }

  Future<void> cancel() async {
    inProgress = false;
    notifyListeners();
    _connection.output.add(ascii.encode('stop'));
    await _connection.finish();
  }

  Future<void> pause() async {
    inProgress = false;
    notifyListeners();
    _connection.output.add(ascii.encode('stop'));
    await _connection.output.allSent;
  }

  Future<void> reasume() async {
    inProgress = true;
    notifyListeners();
    _connection.output.add(ascii.encode('a'));
    await _connection.output.allSent;
  }

  Iterable<DataSample> getLastOf(Duration duration) {
    DateTime startingTime = DateTime.now().subtract(duration);
    int i = samples.length;
    do {
      i -= 1;
      if (i <= 0) {
        break;
      }
    }
    while (samples[i].timestamp.isAfter(startingTime));
    return samples.getRange(i, samples.length);
  }
}
