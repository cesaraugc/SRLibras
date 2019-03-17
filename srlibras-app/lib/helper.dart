import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:rxdart/rxdart.dart';
import 'dart:math';
import 'package:mlkit/mlkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int combinado=0, idx, contParado=0;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  List<int> combined = new List<int>(30);
  bool error=false;
  bool mudou=true;
  String posturaAtual;
  String concatenada = "";
  List<dynamic> results;
  dynamic maxN;
  
  Map<String, List<String>> labels = {
        "alfabeto-detector": ['a', 'b', 'c', 'd', 'e', 'espaco', 'f', 'g', 'h', 'i', 'j', 'k', 
                              'l', 'm', 'n', 'o',
                              'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'],
  };

  FirebaseModelInterpreter detector = FirebaseModelInterpreter.instance;
  FirebaseModelManager manager = FirebaseModelManager.instance;
  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;

  FlutterTts flutterTts = new FlutterTts();
  // dynamic result_speak;
  bool falando = false;

  Map<String, FirebaseModelInputOutputOptions> _ioOptions = {
    "alfabeto-detector": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 30])
      ], [
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 27])
    ]),
    "ft-detector": FirebaseModelInputOutputOptions([
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 30])
      ], [
      FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 2])
    ]),
  };
  


  BehaviorSubject<bool> _canReceive = BehaviorSubject.seeded(true);
  Stream<bool> get canReceive => _canReceive.stream;

  BehaviorSubject<int> _numRcv = BehaviorSubject.seeded(0);
  Stream<int> get numRcv => _numRcv.stream;

  BehaviorSubject<String> _resultNN = BehaviorSubject.seeded('');
  Stream<String> get resultNN => _resultNN.stream;

  BehaviorSubject<String> _hasError = BehaviorSubject.seeded('');
  Stream<String> get hasError => _hasError.stream;

  void setDataRealTime(List<int> data) async {
    for(int i=0; i<data.length; i+=2){
      this.combinado = combine(data[i], data[i+1]);
      // i~/2 é a parte inteira de i/2
      this.combined[i~/2] = this.combinado;
    }
    // dadosRecebidos.
    this.dadosRecebidos.add(this.combined);
    this.error = checkErrors(this.dadosRecebidos);
    if(this.error)
      this._hasError.add("Recebido com erros!");
    else
      this._hasError.add("");

    this.posturaAtual = await toNeuralNetworkRealTime();
    if(this.concatenada.length > 0){
      print("Atual: "+this.posturaAtual + " | concatenada: " + this.concatenada[this.concatenada.length-1]);
      if(this.posturaAtual == this.concatenada[this.concatenada.length-1])
        this.posturaAtual = '';
    }
    
    // if(this.posturaAtual == 'f' || this.posturaAtual == 't'){
    //   this.posturaAtual = await toNeuralNetworkFT();
    // }
    
    if(this.posturaAtual != "espaco"){
      if(this.concatenada.length > 0){
        this.falando = false;
      }
      this.concatenada += this.posturaAtual;
    }
    else{
      if(! this.falando){
        // print("falando...");
        // result_speak = await this.flutterTts.speak(this.concatenada);

        this.flutterTts.speak(this.concatenada).then((val){
          print("falando");
        });

        this.falando = true;
      }
      this.concatenada = "";
    }
    if(this.contParado==20){
      this.concatenada = '';
    }
    this._resultNN.add(this.concatenada);
  }
  
  void setDataForSaving(List<int> data) async {
    // Converte para salvar já como valores int16.
    for(int i=0; i<data.length; i+=2){
      this.combinado = combine(data[i], data[i+1]);
      if(i%60==0){
        this.dadosRecebidos.add([this.combinado]);
      }
      else{
        this.dadosRecebidos.last.add(this.combinado);
      }
    }

    print(this.dadosRecebidos.length);
    this._numRcv.add(this.dadosRecebidos.length);

    if(this.dadosRecebidos.length == 100){
      this.error = checkErrors(this.dadosRecebidos);
      print(this.error?"Recebido com erros!":"Recebido");
      // pode receber
      this._canReceive.add(true);
    }

    if(this.dadosRecebidos.length > 100){
      this.error=true;
    }
  }

  void clear() async{
    await this.flutterTts.setLanguage("pt-BR");
    this.falando=false;
    this.dadosRecebidos = new List<List<int>>();
    // this._canReceive.add(true);
    this._numRcv.add(0);
    this._resultNN.add('');
    this.concatenada = "";
    this.posturaAtual = "";
  }

  void saveToFile(String sinal) async {
    final directory = await getExternalStorageDirectory();
    var now = new DateTime.now();
    if(sinal != ''){
      await new Directory('${directory.path}/$sinal').create(recursive: true);
    }
    final file = sinal!='' ? 
                  File('${directory.path}/$sinal/${sinal}_$now.txt') : 
                  File('${directory.path}/$now.txt');
    print(file);
    await file.writeAsString(this.dadosRecebidos.toString());
  }


  int combine(int b1, int b2){
    int tmp_combined = b2 << 8 | b1;
    return tmp_combined.toSigned(15);
  }


  void setCanReceive(bool p){
    this._canReceive.add(p);
  }


  void setNumRcv(int v){
    this._numRcv.add(v);
  }


  void setLeitura(String s){
    this._resultNN.add(s);
  }


  bool checkErrors(List<List<int>> dado){
    int minValue = 0;
    int maxValue = 0;
    for(var k in dado){
      minValue = k.reduce(min)<minValue? k.reduce(min):minValue;
      maxValue = k.reduce(max)>maxValue? k.reduce(max):maxValue;
    }
    if( (minValue==0 && maxValue==0) || 
        (minValue==-1 && maxValue==0) ||
        (minValue==-1 && maxValue==-1) ){
      this.error=true;
      return true;
    }
    this.error = false;
    return false;
  }


  Future<Uint8List> intToByteListFloat(List<int> listInt30) async {
    print(listInt30);
    var bytesTest = ByteData(120);
    for(var i=0; i<30; i++){
      var o = listInt30[i]/16384.0;
      bytesTest.setFloat32(4*i, o, Endian.little);
    }
    return bytesTest.buffer.asUint8List();
  }


  String getMaxLabel(dynamic res){
    // maior valor
    this.maxN = res.reduce((curr, next) => curr > next? curr: next);
    // índice desse valor
    this.idx = res.indexWhere((value) => value== this.maxN);
    print('Max: $this.maxN --- $this.idx');

    if(this.maxN >= 0.65 && this.mudou){
      this.contParado=0;
      this.mudou = false;
      return labels['alfabeto-detector'][this.idx];
    } else if(this.maxN < 0.65){
      this.mudou = true;
      this.contParado++;
    }
    return '';
  }

  Future<String> toNeuralNetworkRealTime() async{

      this.manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: 'alfabeto-detector', assetFilePath: "assets/models/model_rbfn.tflite"));

      Uint8List input = await intToByteListFloat(combined);
      this.results = await this.interpreter.run(
                      localModelName: 'alfabeto-detector',
                      inputOutputOptions: this._ioOptions['alfabeto-detector'],
                      inputBytes: input);
      dynamic res = this.results[0][0];

      return getMaxLabel(res);
  }

  Future<String> toNeuralNetworkFT() async{

      this.manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: 'ft-detector', assetFilePath: "assets/models/model_FT.tflite"));

      Uint8List input = await intToByteListFloat(this.combined);
      this.results = await this.interpreter.run(
                      localModelName: 'ft-detector',
                      inputOutputOptions: this._ioOptions['ft-detector'],
                      inputBytes: input);
      dynamic res = this.results[0][0];

      return res[0]>res[1]? 'f' : 't';
  }

}