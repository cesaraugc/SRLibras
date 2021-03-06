/* 
 *  Baseado em; https://www.hackster.io/botletics/esp32-ble-android-arduino-ide-awesome-81c67d
 *  Modificado para ler dados de sensores MPU6050 - Bluetooth Low Energy com ESP32
 */ 
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "Wire.h"
 
#include <iostream>
#include <string>
 
BLECharacteristic *pCharacteristic;
 
bool deviceConnected = false;

volatile bool must_read_continuous_data = false;
volatile bool must_read_data_100_times = false;
volatile bool dados_recebidos = true;
volatile bool send_data_continuous = false;
volatile bool send_data_100 = false;
uint8_t todos_dedos[60];
uint8_t meus_dados[13][480];

int16_t ax, ay, az, Tmp;
int16_t gx, gy, gz;
uint8_t todos_dados[1000][60];
uint8_t dado[2];
uint8_t num_read_bytes = 0;
uint8_t num_dados_enviados = 0;

int amostra = 0;
 
// Veja o link seguinte se quiser gerar seus próprios UUIDs:
// https://www.uuidgenerator.net/
 
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART service UUID
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define DHTDATA_CHAR_UUID      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" 
 
const int MPU=0x69;  // I2C address of the MPU-6050 This is valid only when AD0 is HIGH
#define SENSOR0 19
#define SENSOR1 18
#define SENSOR2 5
#define SENSOR3 4
#define SENSOR4 2
 
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      uint16_t conn_id = pServer->getConnId();
      Serial.println(conn_id);
      Serial.println(pServer->getPeerMTU(conn_id));
      pServer->updatePeerMTU(conn_id, 512);
      Serial.println(pServer->getPeerMTU(conn_id));
    };
 
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};
 
class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string rxValue = pCharacteristic->getValue();
    Serial.println(rxValue[0]);

    if (rxValue.find("C") != -1) {
      Serial.println("Iniciando o envio de 100 dados!");
      // Garante que dados não recebidos estarão com valor 0
      for(uint8_t i=0; i<13; i++){
        for(int j=0; j<480; j++){
          meus_dados[i][j] = 0;   
        }
      }

      must_read_data_100_times = true;
      must_read_continuous_data = false;
      send_data_continuous = false;
      send_data_100 = false;
    }
    else if (rxValue.find("S") != -1) {
      Serial.println("Iniciando o envio de dados contínuo!");

      // Garante que dados não recebidos estarão com valor 0
      for(int i=0; i<1000; i++){
        for(int j=0; j<60; j++){
          todos_dados[i][j] = 0;   
        }
      }

      must_read_continuous_data = true;
      must_read_data_100_times = false;
      send_data_continuous = false;
      send_data_100 = false;
      amostra = 0;
    }
    else if (rxValue.find("P") != -1) {
      Serial.println("Parando o envio!");
      must_read_continuous_data = false;
      must_read_data_100_times = false;
      send_data_continuous = false;
      send_data_100 = false;
    }
  }
};
 
void setup() {
  
  Serial.begin(115200);

  /*
  ***** Configuração dos sensores ********
  */

  Serial.println("INICIALIZANDO...");
  pinMode(SENSOR0, OUTPUT);
  pinMode(SENSOR1, OUTPUT);
  pinMode(SENSOR2, OUTPUT);
  pinMode(SENSOR3, OUTPUT);
  pinMode(SENSOR4, OUTPUT);

  digitalWrite(SENSOR0, LOW);
  digitalWrite(SENSOR1, LOW);
  digitalWrite(SENSOR2, LOW);
  digitalWrite(SENSOR3, LOW);
  digitalWrite(SENSOR4, LOW);
  delay(100);

  // Envia sinal de inicialização para todos com AD0=0 (endereço 0x68)
  Wire.begin();
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
  delay(1000);
  Serial.println("FIM DA INICIALIZAÇÃO DOS SENSORES");

  /*
  ***** Configuração do Bluetooth ********
  */
 
  // Create the BLE Device
  BLEDevice::init("ESP32 DHT11"); // Give it a name
//  BLEDevice::setMTU(517);
  BLEDevice::setMTU(512);
  Serial.println(BLEDevice::getMTU());
  
 
  // Configura o dispositivo como Servidor BLE
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
 
  // Cria o servico UART
  BLEService *pService = pServer->createService(SERVICE_UUID);
 
  // Cria uma Característica BLE para envio dos dados
  pCharacteristic = pService->createCharacteristic(
                      DHTDATA_CHAR_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
                       
  pCharacteristic->addDescriptor(new BLE2902());
 
  // cria uma característica BLE para recebimento dos dados
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID_RX,
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
 
  pCharacteristic->setCallbacks(new MyCallbacks());
 
  // Inicia o serviço
  pService->start();
 
  // Inicia a descoberta do ESP32
  pServer->getAdvertising()->start();
  Serial.println("Esperando um cliente se conectar...");
}
 
void loop() {
  if (deviceConnected) {
    if(must_read_continuous_data){
      num_dados_enviados = 0;

      num_read_bytes = 0;
      for(uint8_t j=0; j<5; j++){
        setSensor(j);
        readData();
//        printData();
        splitInBytes();
      }

      send_data_continuous = true;
//      inicializarSensores();
    }
    else if(must_read_data_100_times){
      for(int amostra=0; amostra<13; amostra++){
        for(int u=0; u<8; u++){
          if(amostra==12 && u==4){
            break;
          }
          num_read_bytes = 0;
          for(uint8_t j=0; j<5; j++){
            setSensor(j);
            readData();
            // printData();
            splitInBytes();
          }
          num_dados_enviados++;
          for(int l=0; l<60; l++)
            meus_dados[amostra][l+60*u] = todos_dedos[l];
          
        }
      }
      send_data_100 = true;
    }
  }

  if(send_data_continuous){
    pCharacteristic->setValue(todos_dedos, 60);
    pCharacteristic->notify();
    delay(200);
    send_data_continuous = false;
  }
  else if(send_data_100){
    
    for(int i=0; i<13; i++){
      // o último envio deve ser de 4 dados, para completar os 100 dados
      if(i==12){
        Serial.println("Enviados 240");
        pCharacteristic->setValue(meus_dados[i], 240);
      }
      else{
        Serial.println("Enviados 480");
        pCharacteristic->setValue(meus_dados[i], 480);
      }
      pCharacteristic->notify();
      delay(200);
    }
    send_data_100 = false;
    must_read_data_100_times = false;
  }

}


void setSensor(uint8_t num){
  
  if(num == 0){
    // Serial.println("Setando 0");
    // bluetooth.println("Setando 0");
    digitalWrite(SENSOR0, HIGH);
    digitalWrite(SENSOR1, LOW);
    digitalWrite(SENSOR2, LOW);
    digitalWrite(SENSOR3, LOW);
    digitalWrite(SENSOR4, LOW);
  }
  else if(num == 1){
    // Serial.println("Setando 1");
    // bluetooth.println("Setando 1");
    digitalWrite(SENSOR0, LOW);
    digitalWrite(SENSOR1, HIGH);
    digitalWrite(SENSOR2, LOW);
    digitalWrite(SENSOR3, LOW);
    digitalWrite(SENSOR4, LOW);
  }
  else if(num == 2){
    // Serial.println("Setando 2");
    // bluetooth.println("Setando 2");
    digitalWrite(SENSOR0, LOW);
    digitalWrite(SENSOR1, LOW);
    digitalWrite(SENSOR2, HIGH);
    digitalWrite(SENSOR3, LOW);
    digitalWrite(SENSOR4, LOW);
  }
  else if(num == 3){
    // Serial.println("Setando 3");
    // bluetooth.println("Setando 3");
    digitalWrite(SENSOR0, LOW);
    digitalWrite(SENSOR1, LOW);
    digitalWrite(SENSOR2, LOW);
    digitalWrite(SENSOR3, HIGH);
    digitalWrite(SENSOR4, LOW);
  }
  else if(num == 4){
    // Serial.println("Setando 4");
    // bluetooth.println("Setando 4");
    digitalWrite(SENSOR0, LOW);
    digitalWrite(SENSOR1, LOW);
    digitalWrite(SENSOR2, LOW);
    digitalWrite(SENSOR3, LOW);
    digitalWrite(SENSOR4, HIGH);
  }
}

void readData(){
  Wire.beginTransmission(MPU);    // I2C address code thanks to John Boxall
  Wire.write(0x3B);               // starting with register 0x3B (ACCEL_XOUT_H)
  Wire.endTransmission(false);
  Wire.requestFrom(MPU,14,true);  // request a total of 14 registers
  ax=Wire.read()<<8|Wire.read();  // 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)    
  ay=Wire.read()<<8|Wire.read();  // 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
  az=Wire.read()<<8|Wire.read();  // 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
  Tmp=Wire.read()<<8|Wire.read(); // 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
  gx=Wire.read()<<8|Wire.read();  // 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
  gy=Wire.read()<<8|Wire.read();  // 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)
  gz=Wire.read()<<8|Wire.read();  // 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
//  Wire.endTransmission(true);

  if(ax==0 && ay==0 && az==0 && gx==0 && gy==0 && gz ==0){
    inicializarSensores();
    readData();
  }
}

void splitInBytes(){
  // separa ax em 2 bytes
  dado[0] = ax & 0xff; dado[1] = ax >> 8;
  todos_dedos[num_read_bytes] = dado[0];
  todos_dedos[num_read_bytes+1] = dado[1];

  // separa ay em 2 bytes
  dado[0] = ay & 0xff; dado[1] = ay >> 8;
  todos_dedos[num_read_bytes+2] = dado[0];
  todos_dedos[num_read_bytes+3] = dado[1];

  // separa az em 2 bytes
  dado[0] = az & 0xff; dado[1] = az >> 8;
  todos_dedos[num_read_bytes+4] = dado[0];
  todos_dedos[num_read_bytes+5] = dado[1];

  // separa gx em 2 bytes
  dado[0] = gx & 0xff; dado[1] = gx >> 8;
  todos_dedos[num_read_bytes+6] = dado[0];
  todos_dedos[num_read_bytes+7] = dado[1];

  // separa gy em 2 bytes
  dado[0] = gy & 0xff; dado[1] = gy >> 8;
  todos_dedos[num_read_bytes+8] = dado[0];
  todos_dedos[num_read_bytes+9] = dado[1];

  // separa gz em 2 bytes
  dado[0] = gz & 0xff; dado[1] = gz >> 8;
  todos_dedos[num_read_bytes+10] = dado[0];
  todos_dedos[num_read_bytes+11] = dado[1];

  num_read_bytes += 12;
}


void printData(){
  Serial.print("AcX = "); Serial.print(ax);
  Serial.print(" | AcY = "); Serial.print(ay);
  Serial.print(" | AcZ = "); Serial.print(az);
  // Serial.print(" | Tmp = "); Serial.print(Tmp/340.00+36.53);  //equation for temperature in degrees C from datasheet
  Serial.print(" | GyX = "); Serial.print(gx);
  Serial.print(" | GyY = "); Serial.print(gy);
  Serial.print(" | GyZ = "); Serial.println(gz);
  Serial.println();
}


void printAfter(){
  for(int i=0; i<amostra; i++){
    for(int dedo=0; dedo<5; dedo++){
      ax = todos_dados[i][0+12*dedo] | (todos_dados[i][1+12*dedo] << 8);
      Serial.print("Ax: "); Serial.println(ax);
      ay = todos_dados[i][2+12*dedo] | (todos_dados[i][3+12*dedo] << 8);
      Serial.print("Ay: "); Serial.println(ay);
      az = todos_dados[i][4+12*dedo] | (todos_dados[i][5+12*dedo] << 8);
      Serial.print("Az: "); Serial.println(az);
      gx = todos_dados[i][6+12*dedo] | (todos_dados[i][7+12*dedo] << 8);
      Serial.print("Gx: "); Serial.println(gx);
      gy = todos_dados[i][8+12*dedo] | (todos_dados[i][9+12*dedo] << 8);
      Serial.print("Gy: "); Serial.println(gy);
      gz = todos_dados[i][10+12*dedo] | (todos_dados[i][11+12*dedo] << 8);
      Serial.print("Gz: "); Serial.println(gz);
    }
    Serial.println();
  }
}

void inicializarSensores(){
  Serial.println("INICIALIZANDO...");
  pinMode(SENSOR0, OUTPUT);
  pinMode(SENSOR1, OUTPUT);
  pinMode(SENSOR2, OUTPUT);
  pinMode(SENSOR3, OUTPUT);
  pinMode(SENSOR4, OUTPUT);

  digitalWrite(SENSOR0, LOW);
  digitalWrite(SENSOR1, LOW);
  digitalWrite(SENSOR2, LOW);
  digitalWrite(SENSOR3, LOW);
  digitalWrite(SENSOR4, LOW);
  delay(100);

  // Envia sinal de inicialização para todos com AD0=0 (endereço 0x68)
  Wire.begin();
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
  delay(100);
  Serial.println("FIM DA INICIALIZAÇÃO DOS SENSORES");
}
