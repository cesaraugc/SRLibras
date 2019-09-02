class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int combinado=0, tempo=0, media=0, contador=0;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  Stopwatch stopwatch = new Stopwatch()..start();
  List<int> tempos = new List<int>();
  
  void setData(List<int> data){
    if(dadosRecebidos.length == 0 || dadosRecebidos.last.length == 60){
      // print(dadosRecebidos.last);
      // for(int k=0;k<dadosRecebidos.last.length; k+=2){
      //     combinado = combine(dadosRecebidos.last[k], dadosRecebidos.last[k+1]);
      //     print(combinado);
      // }
      // Adiciona nova linha
      dadosRecebidos.add(data);
    }
    else{
      dadosRecebidos.last = List.from(dadosRecebidos.last)..addAll(data);
      if(dadosRecebidos.last.length == 60){
        tempo = stopwatch.elapsedMilliseconds;
        media += tempo;
        tempos.add(tempo);
        contador++;
        print("Tempo: " + tempo.toString());
        if(contador==100){
          print("Média: " + (media/contador).toString());
          print(tempos);
        }
        stopwatch..reset();
      }
    }
  }

  void clear(){
    dadosRecebidos = [[]];
  }


  int combine(int b1, int b2){
    int combined = b2 << 8 | b1;
    return combined.toSigned(15);
  }
}