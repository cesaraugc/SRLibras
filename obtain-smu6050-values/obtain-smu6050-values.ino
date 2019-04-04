#include "Wire.h"
#include "SoftwareSerial.h"

int16_t ax, ay, az, Tmp;
int16_t gx, gy, gz;

#define LED_PIN 13
#define BIT0 2
#define BIT1 3
#define BIT2 4
#define INH  8
const int MPU=0x69;  // I2C address of the MPU-6050 This is valid only when AD0 is HIGH


// SoftwareSerial bluetooth(2, 3); //TX, RX (Bluetooth)

void setup() {

  Serial.begin(9600);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BIT0, OUTPUT);
  pinMode(BIT1, OUTPUT);
  pinMode(BIT2, OUTPUT);
  pinMode(INH, OUTPUT);

  digitalWrite(INH, HIGH);
  delay(100);
  
  Wire.begin();
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
  delay(1000);
  Serial.println("SETUP");

  // bluetooth.begin(9600);  
}

void loop() {

  for(int i=0; i<5; i++){
    setSensor(i);
    delay(10);
    readAccele();
    delay(1000);
  }; 
  
    //MPU6050 accelgyro(0x69);
  
    //Serial.println("Initializing I2C devices...");
    //accelgyro.initialize();
    
    // read raw accel/gyro measurements from device
    //Serial.println(accelgyro.testConnection() ? "MPU6050 connection successful" : "MPU6050 connection failed");

    //accelgyro.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
    // delay(5);
    // Serial.print(i); Serial.print("Acel. X = "); Serial.print(ax);
    // // bluetooth.print("Acel. X = "); bluetooth.print(ax);
    // Serial.print(" | Y = "); Serial.print(ay);
    // // bluetooth.print(" | Y = "); bluetooth.print(ay);
    // Serial.print(" | Z = "); Serial.print(az);
    // // bluetooth.print(" | Z = "); bluetooth.print(az);
    // Serial.print(" | Gir. X = "); Serial.print(gx);
    // // bluetooth.print(" | Gir. X = "); bluetooth.print(gx);
    // Serial.print(" | Y = "); Serial.print(gy);
    // // bluetooth.print(" | Y = "); bluetooth.print(gy);
    // Serial.print(" | Z = "); Serial.println(gz);
    // // bluetooth.print(" | Z = "); bluetooth.println(gz);
    // Serial.println();

    // //delay(500);
}

void setSensor(int num){
  
  if(num == 0){
    digitalWrite(INH, HIGH);
    Serial.println("Setando 0");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, LOW);
  }
  else if(num == 1){
    digitalWrite(INH, HIGH);
    Serial.println("Setando 1");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, LOW);
  }
  else if(num == 2){
    digitalWrite(INH, HIGH);
    Serial.println("Setando 2");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, LOW);
  }
  else if(num == 3){
    digitalWrite(INH, HIGH);
    Serial.println("Setando 3");
    digitalWrite(BIT0, HIGH);
    digitalWrite(BIT1, HIGH);
    digitalWrite(BIT2, LOW);
    digitalWrite(INH, LOW);
  }
  else if(num == 4){
    digitalWrite(INH, HIGH);
    Serial.println("Setando 4");
    digitalWrite(BIT0, LOW);
    digitalWrite(BIT1, LOW);
    digitalWrite(BIT2, HIGH);
    digitalWrite(INH, LOW);
  }
}

void readAccele()
{
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
    Serial.print("AcX = "); Serial.print(ax);
    Serial.print(" | AcY = "); Serial.print(ay);
    Serial.print(" | AcZ = "); Serial.print(az);
    //Serial.print(" | Tmp = "); Serial.print(Tmp/340.00+36.53);  //equation for temperature in degrees C from datasheet
    Serial.print(" | GyX = "); Serial.print(gx);
    Serial.print(" | GyY = "); Serial.print(gy);
    Serial.print(" | GyZ = "); Serial.println(gz);
    Serial.println();
    delay(5);
}