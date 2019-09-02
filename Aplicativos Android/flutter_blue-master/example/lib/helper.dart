class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int ax=0, ay=0, az=0, gx=0, gy=0, gz=0, ordem=0, combinado=0;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  
  void setData(List<int> data){
    // print(data);
    if(dadosRecebidos.length == 0 || dadosRecebidos.last.length == 60){
      print(dadosRecebidos.last);
      for(int k=0;k<dadosRecebidos.last.length; k+=2){
          combinado = combine(dadosRecebidos.last[k], dadosRecebidos.last[k+1]);
          print(combinado);
      }
      // Adiciona nova linha
      dadosRecebidos.add(data);
      // ordem++;
    }
    else{
      // Adiciona novas colunas na última linha
      dadosRecebidos.last = List.from(dadosRecebidos.last)..addAll(data);
      // print(ordem);
      // ordem<3? ordem++ : ordem=0;
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