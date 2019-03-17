// Baseado no exemplo de Paul DeMarco.
// https://github.com/pauldemarco/flutter_blue/tree/master/example

import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets.dart';
import 'package:srlibras/helper.dart';
import 'package:srlibras/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:strings/strings.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:srlibras/test_classifiers.dart';

String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";

void main() {
  runApp(SRLibrasApp());
  // test_mlp('relu');
  // test_rbfn(0.5);
  // test_KNN();
  // test_rbfn_escolhido();
}

class SRLibrasApp extends StatelessWidget {

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state.toString().substring(15)}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  const FindDevicesScreen({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    
    final MyDataSingleton myData = MyDataSingleton();

    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<PermissionStatus>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncExpand((_) => PermissionHandler().checkPermissionStatus(PermissionGroup.location).asStream()),
                // stream: PermissionHandler().checkPermissionStatus(PermissionGroup.location).asStream(),
                initialData: PermissionStatus.disabled,
                builder: (c, snapshot) {
                  final state = snapshot.data;
                  print(state);
                  if(state == PermissionStatus.denied){
                    PermissionHandler().requestPermissions([PermissionGroup.location]).then( (onValue){
                      print("Permissão adquirida");
                    });
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      state != PermissionStatus.granted?
                      Icon(
                        Icons.location_off,
                          size: 50.0,
                      ) : Container(width: 0.0,height: 0.0),
                      Text(
                          state != PermissionStatus.granted? "Ative a localização." : "",
                          style: Theme.of(context)
                              .primaryTextTheme
                              .subhead
                              .copyWith(color: Colors.red),
                      ),
                    ],
                  );
                }
              ),

              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                      children: 
                        snapshot.data
                          .map((d) { 
                            return ListTile(
                                title: Text(d.name),
                                subtitle: Text(d.id.toString()),
                                trailing: 
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      StreamBuilder<BluetoothDeviceState>(
                                        stream: d.state,
                                        initialData: BluetoothDeviceState.disconnected,
                                        builder: (c, snapshot) {
                                          if (snapshot.data == BluetoothDeviceState.connected) {
                                            return Row(
                                              children: <Widget>[
                                                RaisedButton(
                                                      child: Text('REAL-TIME'),
                                                      onPressed: () { 
                                                        myData.clear();
                                                        d.discoverServices();
                                                        return Navigator.of(context)
                                                          .push(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                DeviceScreenRealTime(device: d, myData: myData)
                                                            )
                                                          );
                                                      },
                                                    ),
                                                RaisedButton(
                                                  child: Text('GET DATA'),
                                                  onPressed: () { 
                                                    myData.clear();
                                                    d.discoverServices();
                                                    return Navigator.of(context)
                                                      .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DeviceScreenGetData(device: d, myData: myData,)
                                                        )
                                                      );
                                                  },
                                                ),
                                              ],
                                            );
                                          }
                                          return Text(snapshot.data.toString());
                                        },
                                      ),
                                    ],
                                  )
                              );
                            }
                          )
                          .toList(),
                    ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                      children: snapshot.data
                          .map(
                            (r) => ScanResultTile(
                                  result: r,
                                  onTap: () {
                                    r.device.connect();
                                  }
                                ),
                          )
                          .toList(),
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            // toKNN();
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}


class DeviceScreenRealTime extends StatelessWidget {
  const DeviceScreenRealTime({Key key, this.device, this.myData //this.textController
                      }) : super(key: key);

  final BluetoothDevice device;
  final MyDataSingleton myData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                    leading: (snapshot.data == BluetoothDeviceState.connected)
                        ? Icon(Icons.bluetooth_connected)
                        : Icon(Icons.bluetooth_disabled),
                    title: Text(
                        'Device is ${snapshot.data.toString().split('.')[1]}.'),
                    subtitle: Text('${device.id}'),
                    trailing: StreamBuilder<bool>(
                      stream: device.isDiscoveringServices,
                      initialData: false,
                      builder: (c, snapshot) => IndexedStack(
                            index: snapshot.data ? 1 : 0,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () => device.discoverServices(),
                              ),
                              IconButton(
                                icon: SizedBox(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.grey),
                                  ),
                                  width: 18.0,
                                  height: 18.0,
                                ),
                                onPressed: null,
                              )
                            ],
                          ),
                    ),
                  ),
            ),

            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                var services = snapshot.data;
                for(var s in services){
                  if(s.uuid.toString().toUpperCase()==SERVICE_UUID){
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: 
                            s.characteristics.map(
                              (c) {
                                myData.clear();
                                return CharacteristicTileRealTime(
                                    characteristic: c,
                                    myData:myData
                                );
                              }
                            )
                            .toList(),
                        ),
                        StreamBuilder<String>(
                          stream: myData.resultNN,
                          initialData: '',
                          builder: (c, snapshot) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child:
                                      Text(
                                        snapshot.data.length>0 ? "Resultado: " + capitalize(snapshot.data) : '',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, 
                                                        foreground: Paint()
                                                          ..style = PaintingStyle.fill
                                                          ..strokeWidth = 6
                                                          ..color = Colors.blue[700],),
                                      )
                                  )
                                ]
                              );
                          }
                        ),
                        StreamBuilder<String>(
                          stream: myData.hasError,
                          // initialData: 'aqui',
                          builder: (c, snapshot) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child:
                                      Text(
                                        snapshot.data,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, 
                                                        foreground: Paint()
                                                          ..style = PaintingStyle.fill
                                                          ..strokeWidth = 6
                                                          ..color = Colors.red[700],),
                                      )
                                  )
                                ]
                              );
                          }
                        ),
                      ]
                    ); 
                  } 
                }
                return Container(width: 0.0,height: 0.0);
              }
            ),
          ],
        ),
      ),
    );
  }
}


final textController = TextEditingController();

// MyDataSingleton myData = MyDataSingleton();
class DeviceScreenGetData extends StatelessWidget {
  const DeviceScreenGetData({Key key, this.device, this.myData //this.textController
                      }) : super(key: key);

  final BluetoothDevice device;
  final MyDataSingleton myData;

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    print(device.name);
    
    return services
        .map(
          (s) { 
              return s.uuid.toString().toUpperCase()==SERVICE_UUID?
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: 
                        s.characteristics.map(
                          (c) {
                            return CharacteristicTileGetData(
                                characteristic: c,
                                myData:myData
                            );
                          }
                        )
                        .toList(),
                    ),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nome do sinal',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        IconButton(
                          iconSize: 70,
                          icon: Icon(Icons.save),
                          onPressed: () {
                            myData.saveToFile(textController.text);
                          },
                        ),
                        IconButton(
                          iconSize: 70,
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            myData.clear();
                          },
                        ),
                      ],
                    ),
                  ]
                ) 
                : Container(width: 0.0,height: 0.0);
          }
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                    leading: (snapshot.data == BluetoothDeviceState.connected)
                        ? Icon(Icons.bluetooth_connected)
                        : Icon(Icons.bluetooth_disabled),
                    title: Text(
                        'Device is ${snapshot.data.toString().split('.')[1]}.'),
                    subtitle: Text('${device.id}'),
                    trailing: StreamBuilder<bool>(
                      stream: device.isDiscoveringServices,
                      initialData: false,
                      builder: (c, snapshot) => IndexedStack(
                            index: snapshot.data ? 1 : 0,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () => device.discoverServices(),
                              ),
                              IconButton(
                                icon: SizedBox(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.grey),
                                  ),
                                  width: 18.0,
                                  height: 18.0,
                                ),
                                onPressed: null,
                              )
                            ],
                          ),
                    ),
                  ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}