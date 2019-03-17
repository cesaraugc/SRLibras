import 'package:mlkit/mlkit.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:ml_linalg/linalg.dart';
import 'package:queries/collections.dart';

FirebaseModelInterpreter detector = FirebaseModelInterpreter.instance;
FirebaseModelManager manager = FirebaseModelManager.instance;
FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;

Map<String, FirebaseModelInputOutputOptions> _ioOptions = {
    "alfabeto-detector": FirebaseModelInputOutputOptions(
        [FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 30])], 
        [FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 27])]
      ),
};

class Dados{
  List<List<double>> X_train;
  List<List<double>> X_test;
  List<int> y_train;
  List<int> y_test;

  Future<List<List<double>>> get_X_train() async{
    if(this.X_train == null || this.X_train.isEmpty){
      print("Lendo arquivo");
      String cs = await rootBundle.loadString('assets/_datasets/dataset_test.csv');
      var cs_list = cs.replaceAll('\r', ',').replaceAll('\n', '').split(",");

      var X_train = new List<List<double>>();
      for(String numStr in cs_list){
        if(numStr.isNotEmpty && numStr.contains('.')){
          double tmp = double.parse(numStr);
          if(X_train.isEmpty || X_train.last.length % 30 == 0){
            X_train.add([tmp]);
          }else{
            X_train.last.add(tmp);
          }
        }
      }
      this.X_train = X_train;
    }
    return this.X_train;
  }

  Future<List<int>> get_y_train() async{
    if(this.y_train == null || this.y_train.isEmpty){
      var cs = await rootBundle.loadString('assets/_datasets/labels_test.csv');
      List<String> y_train = cs.split('\n');
      y_train.removeLast();

      List<int> y_indexes = List<int>();
      for(String l in y_train){
        // Converte string para lista de double
        var lst_y = l.replaceAll('\r', '').split(',').map((element) => double.parse(element)).toList();
        // Encontra índice que possui valor 1.0
        int idx = lst_y.indexWhere((value) => value==1.0);
        y_indexes.add(idx);
      }
      this.y_train = y_indexes;
    }
    return this.y_train;
  }

  Future<List<List<double>>> get_X_test() async{
    if(this.X_test == null || this.X_test.isEmpty){
      var cs = await rootBundle.loadString('assets/_datasets/dataset_test.csv');
      var cs_list = cs.replaceAll('\r', ',').replaceAll('\n', '').split(",");

      var X_test = new List<List<double>>();
      for(String numStr in cs_list){
        if(numStr.isNotEmpty && numStr.contains('.')){
          double tmp = double.parse(numStr);
          if(X_test.isEmpty || X_test.last.length % 30 == 0)
            X_test.add([tmp]);
          else
            X_test.last.add(tmp);
        }
      }
      this.X_test = X_test;
    }
    return this.X_test;
  }

  Future<List<int>> get_y_test() async{
    if(this.y_test == null || this.y_test.isEmpty){
      // get labels
      var cs = await rootBundle.loadString('assets/_datasets/labels_test.csv');
      List<String> y_test = cs.split('\n');
      y_test.removeLast();

      List<int> y_indexes_test = List<int>();
      for(String l in y_test){
        // Converte string para lista de double
        var lst_y = l.replaceAll('\r', '').split(',').map((element) => double.parse(element)).toList();
        // Encontra índice que possui valor 1.0
        int idx = lst_y.indexWhere((value) => value==1.0);
        y_indexes_test.add(idx);
      }
      this.y_test = y_indexes_test;
    }
    return this.y_test;
  }

  // obter protótipos dos K-Means
  Future<List<List<double>>> get_X_Kmeans(int k) async{
    // K deve ser 27, 54, ..., 270
    var cs = await rootBundle.loadString('assets/_datasets/k-means_centroides/por_letra/'+k.toString()+'_clusters.csv');
    var cs_list = cs.replaceAll('\r', ',').replaceAll('\n', '').split(",");
    cs_list.removeLast();

    var X_train_Kmeans = new List<List<double>>();
    for(String numStr in cs_list){
      if(numStr.isNotEmpty && numStr.contains('.')){
        double tmp = double.parse(numStr);
        if(X_train_Kmeans.isEmpty || X_train_Kmeans.last.length % 30 == 0)
          X_train_Kmeans.add([tmp]);
        else
          X_train_Kmeans.last.add(tmp);
      }
    }
    return X_train_Kmeans;
  }

  Future<List<int>> get_y_Kmeans(int k) async{
    var cs = await rootBundle.loadString('assets/_datasets/k-means_centroides/por_letra/'+k.toString()+'_labels_knn-kmeans.csv');
    List<String> y_train = cs.split('\n');
    y_train.removeLast();

    List<int> y_indexes_train = List<int>();
    for(String l in y_train){
      // Converte string para lista de double
      var lst_y = l.replaceAll('\r', '').split(',').map((element) => double.parse(element)).toList();
      // Encontra índice que possui valor 1.0
      int idx = lst_y.indexWhere((value) => value==1.0);
      y_indexes_train.add(idx);
    }
    
    return y_indexes_train;
  }
}

void test_mlp(String ativacao) async {
  // Ativação deve ser 'sigmoide' ou 'relu'
  if(ativacao != 'sigmoide' && ativacao != 'relu'){
    throw("Função de ativação inválida!");
  }

  Dados dados = Dados();
  List<List<double>> X_train = await dados.get_X_train();
  List<int> y_train = await dados.get_y_train();
  
  final directory = await getExternalStorageDirectory();
  int n_samples = 10;
  Map<int, Map<String, double>> tempos_dict = {};

  // neural network with n neurons
  for(int n=1; n<21; n++){
    manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: 'alfabeto-detector-'+n.toString()+"-"+ativacao, 
          assetFilePath: "assets/models/MLP_"+ativacao+"/"+n.toString()+"_model_mlp.tflite"));

    int tempo_total = 0;
    int errors = 0;
    for(int l=0; l<n_samples; l++){
      errors = 0;
      for(int s=0; s<X_train.length; s++){
        List<double> listInt30 = X_train[s];
        var input = await intToByteListFloat(listInt30);
        Stopwatch stopwatch = new Stopwatch()..start();
        var results = await interpreter.run(
                        localModelName: 'alfabeto-detector-'+n.toString()+"-"+ativacao,
                        inputOutputOptions: _ioOptions['alfabeto-detector'],
                        inputBytes: input);
        tempo_total += stopwatch.elapsedMilliseconds;
        var res = results[0][0];
        // pega o indice que possui o maior valor
        var idx_pred = res.indexWhere((value) => value== res.reduce((curr, next) => curr > next? curr: next) );
        errors = idx_pred==y_train[s]? errors : errors+1;
      }
    }
    tempos_dict[n] = {'acc':(1-errors/6750), 'tempo':tempo_total/n_samples.toDouble()};
    final file = File('${directory.path}/' + n.toString() + '_' + ativacao + '_tempos_mlp.txt');
    await file.writeAsString(tempos_dict.toString());
    print(tempo_total/n_samples);
  }
  
  print(tempos_dict);
  final file = File('${directory.path}/tempos_mlp_'+ativacao+'.txt');
  await file.writeAsString(tempos_dict.toString());
}


void test_rbfn(double beta) async {
  // Beta deve ser 1.0, 2.0 ou 0.5
  if(beta != 1.0 && beta != 2.0 && beta != 0.5){
    throw("Valor de beta inválido!");
  }

  Dados dados = Dados();
  List<List<double>> X_train = await dados.get_X_train();
  List<int> y_train = await dados.get_y_train();
  
  final directory = await getExternalStorageDirectory();
  int n_samples = 10;
  Map<int, Map<String, double>> tempos_dict = {};

  String beta_directory;
  if(beta == 1.0)
    beta_directory = '1';
  else if(beta == 2.0)
    beta_directory = '2';
  else if(beta == 0.5)
    beta_directory = '05';

  // neural network with n neurons
  for(int n=27; n<28; n+=27){
    print('alfabeto-detector-'+n.toString()+"-"+beta_directory);
    print("assets/models/RBFN_"+beta_directory+"/"+n.toString()+"_model_rbfn.tflite");
    manager.registerLocalModelSource(FirebaseLocalModelSource(
          modelName: 'alfabeto-detector-'+n.toString()+"-"+beta_directory, 
          assetFilePath: "assets/models/RBFN_"+beta_directory+"/"+n.toString()+"_model_rbfn.tflite"));

    int tempo_total = 0;
    int errors = 0;
    for(int l=0; l<n_samples; l++){
      errors = 0;
      for(int s=0; s<X_train.length; s++){
        List<double> listInt30 = X_train[s];
        var input = await intToByteListFloat(listInt30);
        Stopwatch stopwatch = new Stopwatch()..start();
        var results = await interpreter.run(
                        localModelName: 'alfabeto-detector-'+n.toString()+"-"+beta_directory,
                        inputOutputOptions: _ioOptions['alfabeto-detector'],
                        inputBytes: input);
        tempo_total += stopwatch.elapsedMilliseconds;
        var res = results[0][0];
        // pega o indice que possui o maior valor
        var idx_pred = res.indexWhere((value) => value== res.reduce((curr, next) => curr > next? curr: next) );
        errors = idx_pred==y_train[s]? errors : errors+1;
      }
    }
    tempos_dict[n] = {'acc':(1-errors/6750), 'tempo':tempo_total/n_samples.toDouble()};

    await new Directory('${directory.path}/rbfn/').create(recursive: true);
    final file = File('${directory.path}/rbfn/' + n.toString() + '_' + beta_directory + '_tempos_rbfn.txt');
    await file.writeAsString(tempos_dict.toString());
    print(tempo_total/n_samples);
  }
  
  print(tempos_dict);
  final file = File('${directory.path}/rbfn/tempos_rbfn_'+beta_directory+'.txt');
  await file.writeAsString(tempos_dict.toString());
}


Future<Uint8List> intToByteListFloat(List<double> listInt30) async {
  // print(listInt30);
  var bytesTest = ByteData(120);
  for(var i=0; i<30; i++){
    // var o = listInt30[i]/16384.0;
    bytesTest.setFloat32(4*i, listInt30[i], Endian.little);
  }
  return bytesTest.buffer.asUint8List();
}

class KNN {

  int k = 1;
  KNN(int k){ 
    this.k = k;
  }

  List<List<double>> X_train = List<List<double>>();
  List<int> y_train = List<int>();

  void fit(List<List<double>> X_train, List<int> y_train){
    this.X_train =  X_train;
    this.y_train = y_train;
  }

  int _vote(List<int> ys){
    Map<int, int> voto_dic = {};
    
    for(int y in ys){
      if(voto_dic.containsKey(y)){
        voto_dic[y] += 1;
      }else{
        voto_dic[y] = 1;
      }
    }
    // ordena o dicionário de votos por valor e 
    // retorna a chave do maior valor
    var q = Dictionary.fromMap(voto_dic)
              .orderBy((kv) => kv.value)
              .toDictionary$1((kv) => kv.key, (kv) => kv.value);
    return q.keys.toList().last;
  }

  List<int> predict(X_test){
    var y_pred = List<int>();
    for(int i=0; i<X_test.length; i++){
      
      // cria um vetor com todas as distâncias euclideanas
      List<double> d_list = this.X_train.map((value) {
        final vector = Vector.fromList(X_test[i]);
        final vector2 = Vector.fromList(value);
        return vector.distanceTo(vector2, distance:Distance.euclidean);
      }).toList();

      // cria uma cópia de d_list e ordena
      var d_list_sorted = List<double>.from(d_list);
      d_list_sorted.sort();

      // obtém as k menores distâncias
      var lst_k_y_pred = List<int>();
      for(int l=0; l<k; l++){
        int idx_pred = d_list.indexWhere((value) => value == d_list_sorted[l]);
        lst_k_y_pred.add(this.y_train[idx_pred]);
      }

      // voto de maioria
      y_pred.add(this._vote(lst_k_y_pred));
      print((i+1)/X_test.length);
    }
    return y_pred;
  }

  double score({List<int> y_true, List<int>y_pred}){
    if(y_true.isEmpty && y_pred.isEmpty){
      y_pred = this.predict(this.X_train);
      y_true = this.y_train;
    } 
    double score = 0.0;
    for(int i=0; i<y_true.length; i++){
      if(y_true[i] == y_pred[i])
        score += 1;
    }
    score /= y_true.length;
    return score;
  }

}

void test_KNN() async{
  Dados dados = Dados();

  /*
  // Teste do KNN utilizando todos os dados de treino como protótipos

  List<List<double>> X_train = await dados.get_X_train();
  List<int> y_train = await dados.get_y_train();

  List<List<double>> X_test = await dados.get_X_test();
  List<int> y_test = await dados.get_y_test();

  int k = 1;
  var knn = KNN(k);
  knn.fit(X_train, y_train);
  Stopwatch stopwatch = new Stopwatch()..start();
  var y_pred = knn.predict(X_test);
  int tempo_total = stopwatch.elapsedMilliseconds;
  var score = knn.score(y_true:y_test, y_pred:y_pred);
  print(tempo_total);
  */

  /* Teste do KNN utilizando K-Means */

  for(int k_clusters = 27; k_clusters<271; k_clusters+=27){
    List<List<double>> X_train = await dados.get_X_Kmeans(k_clusters);
    List<int> y_train = await dados.get_y_Kmeans(k_clusters);

    List<List<double>> X_test = await dados.get_X_test();
    List<int> y_test = await dados.get_y_test();

    var knn = KNN(1);
    knn.fit(X_train, y_train);
    Stopwatch stopwatch = new Stopwatch()..start();
    var y_pred = knn.predict(X_test);
    int tempo_total = stopwatch.elapsedMilliseconds;
    var score = knn.score(y_true:y_test, y_pred:y_pred);
    print(tempo_total);
  }

  /*  */
}


void test_rbfn_escolhido() async {
  // função que testa o model_rbfn, que possui N=264 e Beta=1.0

  Dados dados = Dados();
  List<List<double>> X_train = await dados.get_X_train();
  List<int> y_train = await dados.get_y_train();
  
  final directory = await getExternalStorageDirectory();
  int n_samples = 10;
  Map<int, Map<String, double>> tempos_dict = {};

  // neural network with 264 neurons

  manager.registerLocalModelSource(FirebaseLocalModelSource(
        modelName: 'alfabeto-detector-264-rbfn', 
        assetFilePath: "assets/models/model_rbfn.tflite"));

  int tempo_total = 0;
  int errors = 0;
  for(int l=0; l<n_samples; l++){
    errors = 0;
    for(int s=0; s<X_train.length; s++){
      List<double> listInt30 = X_train[s];
      var input = await intToByteListFloat(listInt30);
      Stopwatch stopwatch = new Stopwatch()..start();
      var results = await interpreter.run(
                      localModelName: 'alfabeto-detector-264-rbfn',
                      inputOutputOptions: _ioOptions['alfabeto-detector'],
                      inputBytes: input);
      tempo_total += stopwatch.elapsedMilliseconds;
      var res = results[0][0];
      // pega o indice que possui o maior valor
      var idx_pred = res.indexWhere((value) => value== res.reduce((curr, next) => curr > next? curr: next) );
      errors = idx_pred==y_train[s]? errors : errors+1;
    }
    print(tempo_total);
  }
  tempos_dict[264] = {'acc':(1-errors/6750), 'tempo':tempo_total/n_samples.toDouble()};

  await new Directory('${directory.path}/rbfn/264/').create(recursive: true);
  final file = File('${directory.path}/rbfn/264/264_tempos_rbfn.txt');
  await file.writeAsString(tempos_dict.toString());
  print(tempo_total/n_samples);
}