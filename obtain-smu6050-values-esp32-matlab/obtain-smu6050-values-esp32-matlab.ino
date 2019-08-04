#include "Wire.h"
#include "BluetoothSerial.h"

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

BluetoothSerial bluetooth;

int16_t ax, ay, az, Tmp;
int16_t gx, gy, gz;
uint16_t dado[2];
bool start = false;
unsigned char incomingByte = '\0';
unsigned char incByte = 0;
uint8_t num;
// unsigned long tempo;
// unsigned long piorTempo = 0;

const int MPU=0x69;  // I2C address of the MPU-6050 This is valid only when AD0 is HIGH
#define SENSOR0 19
#define SENSOR1 2
#define SENSOR2 4
#define SENSOR3 5
#define SENSOR4 18

void setup() {

  Serial.begin(115200);

  bluetooth.begin("ESP32test"); //Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");

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
}

void loop() {

  // Serial.print("available" ); Serial.println(bluetooth.available());
  if(bluetooth.available()){
    incByte = bluetooth.read();
    if(incByte != 0){

      // Comandos '0', '1', '2', '3' e '4' pegam os valores dos respectivos sensores
      if(incByte >= '0' && incByte <= '4'){
        num = incByte - '0'; // converte char para número
        setSensor(num);
        readData();

//        Serial.println(num);
//        Serial.print("ax: "); Serial.println(ax);
//        Serial.print("ay: "); Serial.println(ay);
//        Serial.print("az: "); Serial.println(az);
//        Serial.print("gx: "); Serial.println(gx);
//        Serial.print("gy: "); Serial.println(gy);
//        Serial.print("gz: "); Serial.println(gz);

        // Separa cada dado de 16 bits em 2 bytes para enviá-los 
        // separadamente pela função write, que só escreve 1 byte
        dado[0] = ax & 0xff; dado[1] = ax >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        dado[0] = ay & 0xff; dado[1] = ay >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        dado[0] = az & 0xff; dado[1] = az >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        dado[0] = gx & 0xff; dado[1] = gx >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        dado[0] = gy & 0xff; dado[1] = gy >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        dado[0] = gz & 0xff; dado[1] = gz >> 8;
        bluetooth.write(dado[0]); bluetooth.write(dado[1]);
      }

      // Comando 't' para receber dados de Todos os 5 sensores
      else if(incByte == 't'){
        for(uint8_t j=0; j<5; j++){
          setSensor(j);
          readData();

//          Serial.println(j);
//          Serial.print("ax: "); Serial.println(ax);
//          Serial.print("ay: "); Serial.println(ay);
//          Serial.print("az: "); Serial.println(az);
//          Serial.print("gx: "); Serial.println(gx);
//          Serial.print("gy: "); Serial.println(gy);
//          Serial.print("gz: "); Serial.println(gz);

          // Separa cada dado de 16 bits em 2 bytes para enviá-los 
          // separadamente pela função write, que só escreve 1 byte
          dado[0] = ax & 0xff; dado[1] = ax >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
          dado[0] = ay & 0xff; dado[1] = ay >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
          dado[0] = az & 0xff; dado[1] = az >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
          dado[0] = gx & 0xff; dado[1] = gx >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
          dado[0] = gy & 0xff; dado[1] = gy >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
          dado[0] = gz & 0xff; dado[1] = gz >> 8;
          bluetooth.write(dado[0]); bluetooth.write(dado[1]);
        }
      }

      incByte = 0;
    }
  }
}

void setSensor(int num){
  
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
  // Serial.print("AcX = "); Serial.print(ax);
  bluetooth.print("Acel. X = "); bluetooth.print(ax);
  // Serial.print(" | AcY = "); Serial.print(ay);
  bluetooth.print(" | Y = "); bluetooth.print(ay);
  // Serial.print(" | AcZ = "); Serial.print(az);
  bluetooth.print(" | Z = "); bluetooth.print(az);
  //Serial.print(" | Tmp = "); Serial.print(Tmp/340.00+36.53);  //equation for temperature in degrees C from datasheet
  // Serial.print(" | GyX = "); Serial.print(gx);
  bluetooth.print(" | Gir. X = "); bluetooth.print(gx);
  // Serial.print(" | GyY = "); Serial.print(gy);
  bluetooth.print(" | Y = "); bluetooth.print(gy);
  // Serial.print(" | GyZ = "); Serial.println(gz);
  bluetooth.print(" | Z = "); bluetooth.println(gz);
  // Serial.println();
  bluetooth.println();
}
