import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:SrLibras/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math';
// import 'package:mlkit/mlkit.dart';
import 'package:mlkit/mlkit.dart';



class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int combinado=0, idx;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  List<List<int>> bytesRecebidos = new List<List<int>>();
  bool podeReceber= true;
  bool error=false;
  String ultima_leitura;
  List<dynamic> results;
  dynamic res, maxN;
  Uint8List input;
  Map<String, List<String>> labels = {
        "alfabeto-detector": ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'l', 'm', 'n', 'o',
                              'p', 'q', 'r', 's', 't', 'u', 'v', 'w'],
  };

  FirebaseModelInterpreter detector = FirebaseModelInterpreter.instance;
  FirebaseModelManager manager = FirebaseModelManager.instance;
  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;

  Map<String, FirebaseModelInputOutputOptions> _ioOptions = {
    "alfabeto-detector": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 30])
      ], [
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 20])
    ]),
  };


  BehaviorSubject<bool> _canReceive = BehaviorSubject.seeded(false);
  Stream<bool> get canReceive => _canReceive.stream;

  BehaviorSubject<int> _numRcv = BehaviorSubject.seeded(0);
  Stream<int> get numRcv => _numRcv.stream;

  BehaviorSubject<String> _resultNN = BehaviorSubject.seeded('');
  Stream<String> get resultNN => _resultNN.stream;
  
  void setData(List<int> data) async {
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
    for(int j=0; j<data.length; j++){
      if(j%30==0)
        bytesRecebidos.add([data[j]]);
      else
        bytesRecebidos.last.add(data[j]);
    }
    print(dadosRecebidos.length);
    _numRcv.add(dadosRecebidos.length);
    if(dadosRecebidos.length == 100){
      error = allZero();
      print(error?"Recebido com erros!":"Recebido");
      podeReceber=true;
      _canReceive.add(true);
      ultima_leitura = await toNeuralNetwork();
      _resultNN.add(ultima_leitura);
      print(ultima_leitura);
    }
    if(dadosRecebidos.length > 100){
      error=true;
    }
  
  }

  void clear(){
    error=false;
    dadosRecebidos = new List<List<int>>();
    _canReceive.add(true);
    _numRcv.add(0);
    _resultNN.add('');
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
                  File('${directory.path}/$now.txt');
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

  void setLeitura(String s){
    _resultNN.add(s);
  }

  bool allZero(){
    int minValue = 0;
    int maxValue = 0;
    for(var k in dadosRecebidos){
      minValue = k.reduce(min)<minValue? k.reduce(min):minValue;
      maxValue = k.reduce(max)>maxValue? k.reduce(max):maxValue;
    }
    if( (minValue==0 && maxValue==0) || 
        (minValue==-1 && maxValue==0) ||
        (minValue==-1 && maxValue==-1) ){
      error=true;
      return true;
    }
    error = false;
    return false;
  }


  Future<String> toNeuralNetwork() async{
      // manager.registerRemoteModelSource(FirebaseRemoteModelSource(
      //   modelName: 'alfabeto-detector',
      //   enableModelUpdates: true,
      //   initialDownloadConditions:
      //       FirebaseModelDownloadConditions(requireWifi: true),
      //   updatesDownloadConditions:
      //       FirebaseModelDownloadConditions(requireWifi: true)));

      manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: 'alfabeto-detector', assetFilePath: "assets/model.tflite"));

      input = await intToByteListFloat();
      results = await interpreter.run(
                      localModelName: 'alfabeto-detector',
                      inputOutputOptions: _ioOptions['alfabeto-detector'],
                      inputBytes: input);
      res = results[0][0];

      maxN = res[0];
      idx = 0;
      for(int i=1; i<res.length; i++){
        if(maxN.compareTo(res[i]) < 0){
          maxN = res[i];
          idx = i;
        }
      }
      print('Max: $maxN --- $idx');
      return labels['alfabeto-detector'][idx] + ":" + maxN.toString();
  }


  Future<Uint8List> intToByteListFloat() async {
    var bytesTest = ByteData(120);
    for(var i=0; i<30; i++){
      var o = dadosRecebidos[0][i]/16384.0;
      bytesTest.setFloat32(4*i, o, Endian.little);
    }
    return bytesTest.buffer.asUint8List();
  }

}