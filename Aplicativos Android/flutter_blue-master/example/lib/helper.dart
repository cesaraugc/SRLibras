class MyDataSingleton {
  static MyDataSingleton _instance;
  factory MyDataSingleton() {
    _instance ??= MyDataSingleton._internalConstructor();
    return _instance;
  }
  MyDataSingleton._internalConstructor();

  int combinado=0;
  List<List<int>> dadosRecebidos = new List<List<int>>();
  
  void setData(List<int> data){
      // print(dadosRecebidos.last);
      // for(int k=0;k<dadosRecebidos.last.length; k+=2){
      //     combinado = combine(dadosRecebidos.last[k], dadosRecebidos.last[k+1]);
      //     print(combinado);
      // }
      // Adiciona nova linha
      dadosRecebidos.add(data);
    
  }

  void clear(){
    dadosRecebidos = [[]];
  }

  void saveToFile(){
    
  }


  int combine(int b1, int b2){
    int combined = b2 << 8 | b1;
    return combined.toSigned(15);
  }
}