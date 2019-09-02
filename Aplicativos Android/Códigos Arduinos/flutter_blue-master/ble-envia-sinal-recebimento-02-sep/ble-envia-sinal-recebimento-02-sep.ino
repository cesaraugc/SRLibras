/* 
 *  Programa baseado no programa original desenvolvido por Timothy Woo 
 *  Tutorial do projeto original; https://www.hackster.io/botletics/esp32-ble-android-arduino-ide-awesome-81c67d
 *  Modificado para ler dados do sensor DHT11 - Bluetooth Low Energy com ESP32
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
const int LED = 2; // Could be different depending on the dev board. I used the DOIT ESP32 dev board.

int humidity = 0;
int temperature = 0;
volatile bool must_read_data = false;
volatile bool dados_recebidos = true;
uint8_t num[20];
uint8_t num2[20];
uint8_t num3[20];
uint8_t todos_dedos[60];

int16_t ax, ay, az, Tmp;
int16_t gx, gy, gz;
uint8_t dado[2];
uint8_t num_read_bytes = 0;
 
// Veja o link seguinte se quiser gerar seus próprios UUIDs:
// https://www.uuidgenerator.net/
 
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART service UUID
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define DHTDATA_CHAR_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" 
 
const int MPU=0x69;  // I2C address of the MPU-6050 This is valid only when AD0 is HIGH
#define SENSOR0 19
#define SENSOR1 2
#define SENSOR2 4
#define SENSOR3 5
#define SENSOR4 18
 
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };
 
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};
 
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();
      Serial.println(rxValue[0]);
      
      if (rxValue.length() > 0) {
        Serial.println("*********");
        Serial.print("Received Value: ");
 
        for (int i = 0; i < rxValue.length(); i++) {
          Serial.print(rxValue[i]);
        }
        Serial.println();
        Serial.println("*********");
      }
    
      if (rxValue.find("B") != -1) {
        Serial.println("Dados Recebidos!");
        dados_recebidos = true;
      }
      else if (rxValue.find("S") != -1) {
        Serial.println("Iniciando o envio de dados!");
        must_read_data = true;
        dados_recebidos = true;
      }
      else if (rxValue.find("P") != -1) {
        Serial.println("Parando o envio!");
        must_read_data = false;
      }
    }
};
 
void setup() {
  Serial.begin(115200);
 
  pinMode(LED, OUTPUT);

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
  Serial.println("FIM DA INICIALIZAÇÃO");

  /*
  ***** Configuração do Bluetooth ********
  */
 
  // Create the BLE Device
  BLEDevice::init("ESP32 DHT11"); // Give it a name
 
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
  if (deviceConnected && must_read_data) {
    
    for(uint8_t j=0; j<5; j++){
      setSensor(j);
      readData();
      printData();

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
    num_read_bytes = 0;

    for(uint8_t j=0; j<20; j++){
      num[j] = todos_dedos[j];
      num2[j] = todos_dedos[j+20];
      num3[j] = todos_dedos[j+40];
    }

    while(!dados_recebidos){}
    dados_recebidos = false;
    
    pCharacteristic->setValue(num, 20);
    pCharacteristic->notify();
    Serial.println("*** Dados enviado: 0 a 19 ***");

    while(!dados_recebidos){}
    dados_recebidos = false;
    
    pCharacteristic->setValue(num2, 20);
    pCharacteristic->notify();
    Serial.println("*** Dados enviado: 20 a 39 ***");

    while(!dados_recebidos){}
    dados_recebidos = false;
    
    pCharacteristic->setValue(num3, 20);
    pCharacteristic->notify();
    Serial.println("*** Dados enviado: 40 a 59 ***");
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
