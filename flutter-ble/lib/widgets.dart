// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
    if (characteristicTiles.length > 0 && service.uuid.toString().toUpperCase()=="6E400001-B5A3-F393-E0A9-E50E24DCCA9E") {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,
      );
    } 
    else{
      return new Container(width: 0.0,height: 0.0);
    }
    // else {
    //   return ListTile(
    //     title: Text('Service'),
    //     subtitle:
    //         Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
    //   );
    // }
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
        // if(uuid == "6e400003-b5a3-f393-e0a9-e50e24dcca9e" ){
        //   characteristic.setNotifyValue(true);
        // }
        return ExpansionTile(
          title: ListTile(
            title: uuidColumn(uuid, context),
            //subtitle: Text(value.toString()),
            subtitle: uuid == "6e400003-b5a3-f393-e0a9-e50e24dcca9e" ? Text(value.toString()) : Text(''),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: uuidRow(context, uuid, onReadPressed, onStartPressed, onStopPressed, onNotificationPressed, characteristic.isNotifying),
          // children: descriptorTiles,
          //initiallyExpanded: true,
        );
      },
    );
  }
}

// class DescriptorTile extends StatelessWidget {
//   final BluetoothDescriptor descriptor;
//   final VoidCallback onReadPressed;
//   final VoidCallback onStartPressed;

//   const DescriptorTile(
//       {Key key, this.descriptor, this.onReadPressed, this.onStartPressed})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Text('Descriptor'),
//           Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
//               style: Theme.of(context)
//                   .textTheme
//                   .body1
//                   .copyWith(color: Theme.of(context).textTheme.caption.color))
//         ],
//       ),
//       subtitle: StreamBuilder<List<int>>(
//         stream: descriptor.value,
//         initialData: descriptor.lastValue,
//         builder: (c, snapshot) => Text(snapshot.data.toString()),
//       ),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: <Widget>[
//           IconButton(
//             icon: Icon(
//               Icons.file_download,
//               color: Theme.of(context).iconTheme.color.withOpacity(0.5),
//             ),
//             onPressed: onReadPressed,
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.file_upload,
//               color: Theme.of(context).iconTheme.color.withOpacity(0.5),
//             ),
//             onPressed: onStartPressed,
//           )
//         ],
//       ),
//     );
//   }
// }

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


Column uuidColumn (String uuid, context){
  if(uuid == "6e400002-b5a3-f393-e0a9-e50e24dcca9e"){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Text('Ações'),
        // Text(
        //     '0x${uuid.toUpperCase().substring(4, 8)}',
        //     style: Theme.of(context).textTheme.body1.copyWith(
        //         color: Theme.of(context).textTheme.caption.color))
        Text('')
      ],
    );
  }
  else if(uuid == "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Text('Leitura'),
        // Text(
        //     '0x${uuid.toUpperCase().substring(4, 8)}',
        //     style: Theme.of(context).textTheme.body1.copyWith(
        //         color: Theme.of(context).textTheme.caption.color))
        Text('')
      ],
    );
}

Row uuidRow(context, uuid, onReadPressed, onStartPressed, onStopPressed, onNotificationPressed, isNotifying){
  if(uuid == "6e400002-b5a3-f393-e0a9-e50e24dcca9e"){
    return Row(
        mainAxisSize: MainAxisSize.min,
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
      );
  }
  else if(uuid == "6e400003-b5a3-f393-e0a9-e50e24dcca9e"){
    return Row(
        mainAxisSize: MainAxisSize.min,
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
                isNotifying
                    ? Icons.sync_disabled
                    : Icons.sync,
                color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
            onPressed: onNotificationPressed,
          )
        ],
      );
  }
}