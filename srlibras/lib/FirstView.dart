import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './BackgroundCollectingTask.dart';
import './SelectBondedDevicePage.dart';
import './BackgroundCollectedPage.dart';
import 'package:scoped_model/scoped_model.dart';

class FirstView extends StatefulWidget {
  @override
  _FirstView createState() => new _FirstView();
}

class _FirstView extends State<FirstView>{

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;
  BluetoothDevice selectedDevice;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();
    
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() { _bluetoothState = state; });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() { _address = address; });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() { _name = name; });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("SrLibras"),
      ),
      body: Container(
        height: height,
        child: ListView(
          children: <Widget>[
            Divider(),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async { // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }
                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Text(_bluetoothState.toString()),
              trailing: RaisedButton(
                child: const Text('Settings'),
                onPressed: () { 
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                "Aplicativo para ler dados dos sensores da luva via Bluetooth",
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: "Roboto",
                    fontStyle: FontStyle.normal,
                    fontSize: 20.0),
              ),
            ),

            ListTile(
              title: RaisedButton(
                child: (
                  (_collectingTask != null && _collectingTask.inProgress) 
                  ? const Text('Disconnect and stop background collecting')
                  : const Text('Connect to start background collecting') 
                ),
                onPressed: () async {
                  if (_collectingTask != null && _collectingTask.inProgress) {
                    await _collectingTask.cancel();
                    setState(() {/* Update for `_collectingTask.inProgress` */});
                  }
                  else {
                    selectedDevice = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) { return SelectBondedDevicePage(checkAvailability: false); })
                    );

                    if (selectedDevice != null) {
                      await _startBackgroundTask(context, selectedDevice);
                      setState(() {/* Update for `_collectingTask.inProgress` */});
                    }
                  }
                },
              ),
            ),
            ListTile(
              title: RaisedButton(
                child: const Text('View background collected data'),
                onPressed: (_collectingTask != null) ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return ScopedModel<BackgroundCollectingTask>(
                        model: _collectingTask,
                        child: BackgroundCollectedPage(),
                      );
                    })
                  );
                } : null,
              )
            ),

            ListTile(
              title: RaisedButton(
                child: (
                  Text('Collect New Data.') 
                ),
                onPressed: () async {
                  if (_collectingTask != null && _collectingTask.inProgress) {
                    while(true){
                    try{
                      _collectingTask.reasume();
                      //var data = _collectingTask.getData();
                      var connection = _collectingTask.getConnection();
                      
                      connection.input.listen((data) {
                        print("AQUI");
                        print(data);
                      }).onDone(() {});
                      //print(data);
                    } catch (exception) {
                      print('Cannot connect, exception occured');
                    }
                    }
                  }
                },
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Future<void> _startBackgroundTask(BuildContext context, BluetoothDevice server) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask.start();
    }
    catch (ex) {
      if (_collectingTask != null) {
        _collectingTask.cancel();
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}