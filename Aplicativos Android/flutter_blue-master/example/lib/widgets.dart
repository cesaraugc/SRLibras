// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

String UUID_READ = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
String UUID_WRITE = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";


class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}


class CharacteristicTile2 extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final MyDataSingleton myData;

  const CharacteristicTile2(
      {Key key,
      this.characteristic,
      this.myData});

  @override
  _CharacteristicTile2State createState() => new _CharacteristicTile2State(
    characteristic: characteristic,
    myData:myData
  );
}


class _CharacteristicTile2State extends State<CharacteristicTile2> {
  final BluetoothCharacteristic characteristic;
  final MyDataSingleton myData;

  _CharacteristicTile2State(
      {Key key,
      this.characteristic,
      this.myData});

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        String uuid = characteristic.uuid.toString();
        // MyDataSingleton myData = MyDataSingleton();
        if(uuid == UUID_READ && value.length > 0){
          myData.setData(value.toList());
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            uuid == UUID_READ?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    iconSize: 70,
                    icon: Icon(
                        characteristic.isNotifying
                            ? Icons.sync_disabled
                            : Icons.sync,
                        color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
                    onPressed: (){
                      characteristic.setNotifyValue(!characteristic.isNotifying);
                    },
                  )
                ],
              ) : Container(width: 0.0,height: 0.0),

            
            
            uuid == UUID_WRITE?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StreamBuilder<bool>(
                    stream: myData.canReceive,
                    initialData: true,
                    builder: (c, snapshot) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _buildButtons(snapshot.data),
                          ]
                        );
                      }
                  ),

                  StreamBuilder<int>(
                    stream: myData.numRcv,
                    initialData: 0,
                    builder: (c, snapshot) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(snapshot.data.toString()),
                            Text(myData.error? "Recebido com erro.": "Recebido corretamente.")
                          ]
                        );
                      }
                  )
                ]
              ) : Container(width: 0.0,height: 0.0),
            
          ],
        );
      },
    );
  }

  Widget _buildButtons(podeReceber) {
    return new IconButton(
        iconSize: 70,
        icon: podeReceber?
          Icon(
            Icons.play_arrow,
            color: Theme.of(context).iconTheme.color.withOpacity(0.5),
          ) :
          SizedBox(
            child: CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
        onPressed: podeReceber?
          (){
            myData.clear(); 
            characteristic.write([83]);
            myData.setReceive(false);
          } : null
    );
  }
}


class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key key, @required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }
}