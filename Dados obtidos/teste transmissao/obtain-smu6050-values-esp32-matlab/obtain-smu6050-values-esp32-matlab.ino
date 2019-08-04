#include "Wire.h"
#include "BluetoothSerial.h"

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

BluetoothSerial bluetooth;

unsigned char incByte = 0;
uint8_t num;

void setup() {

  Serial.begin(115200);

  bluetooth.begin("ESP32test"); //Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");

  Serial.println("FIM DA INICIALIZAÇÃO");
}

void loop() {

  // Serial.print("available" ); Serial.println(bluetooth.available());
  if(bluetooth.available()){
    incByte = bluetooth.read();
    if(incByte == 'a'){
        Serial.println("Recebido");
        for(uint8_t j=0; j<10; j++){
          bluetooth.write(j);
        }
    }
  incByte = 0;
  }
    
}
