#include "Wire.h"
#include "SoftwareSerial.h"

int16_t ax, ay, az, Tmp;
int16_t gx, gy, gz;
bool start = false;

#define LED_PIN 13
#define BIT0 2
#define BIT1 3
#define BIT2 4
#define INH  12
const int MPU=0x68;  // I2C address of the MPU-6050 This is valid only when AD0 is HIGH
unsigned char incomingByte = '\0';

SoftwareSerial bluetooth(10, 11); //TX, RX (Bluetooth)

void setup() {

  Serial.begin(9600);
  bluetooth.begin(115200);  

  Serial.println("INICIALIZANDO...");
  pinMode(LED_PIN, OUTPUT);
  pinMode(BIT0, OUTPUT);
  pinMode(BIT1, OUTPUT);
  pinMode(BIT2, OUTPUT);
  pinMode(INH, OUTPUT);

  digitalWrite(INH, LOW); //Ativa inibição
  delay(100);
  
  Wire.begin();
  Wire.beginTransmission(0x69);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
  delay(1000);

  digitalWrite(INH, HIGH);
  Serial.println("FIM DA INICIALIZAÇÃO");
  Serial.println("Obtendo os valores");
}

void loop() {

  if(bluetooth.available()){
    incomingByte = bluetooth.read();
    if(incomingByte == 'a'){
      start = true;
      Serial.println("OK");
    }
  }
  if(start){
    for(int i=0; i<5; i++){
      setSensor(i);
      delay(10);
      readData();
      Serial.println(ax);
      bluetooth.print(ax); bluetooth.print(",");
      Serial.println(ay);
      bluetooth.print(ay); bluetooth.print(",");
      Serial.println(az);
      bluetooth.print(az); bluetooth.print(",");
      Serial.println(gx);
      bluetooth.print(gx); bluetooth.print(",");
      Serial.println(gy);
      bluetooth.print(gy); bluetooth.print(",");
      Serial.println(gz);
      bluetooth.print(gz); bluetooth.println(",");
      delay(1000);
    }
  }

  //  for(int i=0; i<5; i++){
//    setSensor(i);
//    delay(10);
//    readData();
//    printData();
//    delay(1000);
//  }; 

}

void setSensor(int num){
  
  if(num == 0){
    digitalWrite(INH, LOW);
    Serial.println("Setando 0");
    //bluetooth.println("Setando 0");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, HIGH);
  }
  else if(num == 1){
    digitalWrite(INH, LOW);
    Serial.println("Setando 1");
//    bluetooth.println("Setando 1");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, HIGH);
  }
  else if(num == 2){
    digitalWrite(INH, LOW);
    Serial.println("Setando 2");
//    bluetooth.println("Setando 2");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, HIGH);
  }
  else if(num == 3){
    digitalWrite(INH, LOW);
    Serial.println("Setando 3");
//    bluetooth.println("Setando 3");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, HIGH);
  }
  else if(num == 4){
    digitalWrite(INH, LOW);
    Serial.println("Setando 4");
//    bluetooth.println("Setando 4");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, HIGH);
    digitalWrite(INH, HIGH);
  }
  else if(num == 5){
    digitalWrite(INH, LOW);
    Serial.println("Setando 5");
//    bluetooth.println("Setando 5");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, HIGH);
    digitalWrite(INH, HIGH);
  }
  else if(num == 6){
    digitalWrite(INH, LOW);
    Serial.println("Setando 6");
//    bluetooth.println("Setando 6");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, HIGH);
    digitalWrite(INH, HIGH);
  }
  else if(num == 7){
    digitalWrite(INH, LOW);
    Serial.println("Setando 7");
//    bluetooth.println("Setando 7");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, HIGH);
    digitalWrite(INH, HIGH);
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
  Wire.endTransmission(true);
}

void printData(){
  Serial.print("AcX = "); Serial.print(ax);
  bluetooth.print("Acel. X = "); //bluetooth.print(ax);
  bluetooth.write(ax);
  Serial.print(" | AcY = "); Serial.print(ay);
  bluetooth.print(" | Y = "); bluetooth.print(ay);
  Serial.print(" | AcZ = "); Serial.print(az);
  bluetooth.print(" | Z = "); bluetooth.print(az);
  //Serial.print(" | Tmp = "); Serial.print(Tmp/340.00+36.53);  //equation for temperature in degrees C from datasheet
  Serial.print(" | GyX = "); Serial.print(gx);
  bluetooth.print(" | Gir. X = "); bluetooth.print(gx);
  Serial.print(" | GyY = "); Serial.print(gy);
  bluetooth.print(" | Y = "); bluetooth.print(gy);
  Serial.print(" | GyZ = "); Serial.println(gz);
  bluetooth.print(" | Z = "); bluetooth.println(gz);
  Serial.println();
  bluetooth.println();
}
