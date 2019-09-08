import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:SrLibras/widgets.dart';
import 'package:rxdart/rxdart.dart';

class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int combinado=0;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  bool podeReceber= true;
  bool error=false;

  BehaviorSubject<bool> _canReceive = BehaviorSubject.seeded(false);
  Stream<bool> get canReceive => _canReceive.stream;

  BehaviorSubject<int> _numRcv = BehaviorSubject.seeded(0);
  Stream<int> get numRcv => _numRcv.stream;
  
  void setData(List<int> data){
    // Converte para salvar já como valores int16.
    for(int i=0; i<data.length; i+=2){
      combinado = combine(data[i], data[i+1]);
      if(i%60==0){
        dadosRecebidos.add([combinado]);
      }
      else{
        dadosRecebidos.last.add(combinado);
      }
    }
    print(dadosRecebidos.length);
    _numRcv.add(dadosRecebidos.length);
    if(dadosRecebidos.length == 100){
      podeReceber=true;
      _canReceive.add(true);
      print("Recebido!");
    }
    if(dadosRecebidos.length > 100){
      error=true;
    }
  }

  void clear(){
    dadosRecebidos = new List<List<int>>();
    _canReceive.add(true);
  }

  void saveToFile(String sinal) async {
    // convertData();
    final directory = await getExternalStorageDirectory();
    var now = new DateTime.now();
    if(sinal != ''){
      await new Directory('${directory.path}/$sinal').create(recursive: true);
    }
    final file = sinal!='' ? 
                  File('${directory.path}/$sinal/${sinal}_$now.txt') : 
                  File('${directory.path}/my_file_$now.txt');
    print(file);
    await file.writeAsString(dadosRecebidos.toString());
  }


  int combine(int b1, int b2){
    int combined = b2 << 8 | b1;
    return combined.toSigned(15);
  }

  void setReceive(bool p){
    _canReceive.add(p);
  }

  void setNumRcv(int v){
    _numRcv.add(v);
  }
}