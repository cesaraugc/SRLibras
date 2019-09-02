// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'helper.dart';

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

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0 && 
        service.uuid.toString().toUpperCase()=="6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
      
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: characteristicTiles,
        );
    } 
    else{
      return new Container(width: 0.0,height: 0.0);
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  // final List<DescriptorTile> descriptorTiles;
  final VoidCallback onReadPressed;
  final VoidCallback onStartPressed;
  final VoidCallback onStopPressed;
  final VoidCallback onNotificationPressed;

  const CharacteristicTile(
      {Key key,
      this.characteristic,
      // this.descriptorTiles,
      this.onReadPressed,
      this.onStartPressed,
      this.onNotificationPressed,
      this.onStopPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        String uuid = characteristic.uuid.toString();
        MyDataSingleton mydata = MyDataSingleton();
        if(uuid == UUID_READ ){
          // characteristic.setNotifyValue(true);
          if(value.length == 20){
            //print(value);
            mydata.setData(value.toList());
          }
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            uuid == UUID_READ && value.length>0?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(value.sublist(0,10).toString()),
                ],
              ) : Container(width: 0.0,height: 0.0),
            uuid == UUID_READ && value.length>0?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(value.sublist(10,20).toString())
                ],
              ) : Container(width: 0.0,height: 0.0),
            uuid == UUID_READ?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // IconButton(
                  //   iconSize: 70,
                  //   icon: Icon(
                  //     Icons.file_download,
                  //     color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                  //   ),
                  //   onPressed: onReadPressed,
                  // ),
                  IconButton(
                    iconSize: 70,
                    icon: Icon(
                        characteristic.isNotifying
                            ? Icons.sync_disabled
                            : Icons.sync,
                        color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
                    onPressed: onNotificationPressed,
                  )
                ],
              ) : Container(width: 0.0,height: 0.0),
            uuid == UUID_WRITE?
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    iconSize: 70,
                    icon: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                    ),
                    onPressed: onStartPressed,
                  ),
                  IconButton(
                    iconSize: 70,
                    icon: Icon(
                      Icons.stop,
                      color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                    ),
                    onPressed: onStopPressed,
                  ),
                ],
              ) : Container(width: 0.0,height: 0.0),
            uuid == UUID_WRITE ? 
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    iconSize: 70,
                    icon: Icon(Icons.save,
                        color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
                    onPressed: () {},
                  ),
                ],
              ) : Container(width: 0.0,height: 0.0),
            uuid == UUID_WRITE ?
              TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Nome do sinal',
                    ),
              ) : Container(width: 0.0,height: 0.0),
          ],
        );
      },
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