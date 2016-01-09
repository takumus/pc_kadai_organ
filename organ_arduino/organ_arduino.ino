#include <Servo.h>
#include <Servo2.h>

//618-2458 S1
//655-2640 S2

unsigned long swt;

Servo2 sv1;
Servo2 sv2;
Servo2 sv3;
boolean sw1Pressed;
boolean sw2Pressed;
float sv1r = 0;
float sv2r = 0;
float sv3r = 0;
boolean led1 = true;
boolean led2 = true;
bool requestVolume = false;
void setup()
{
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
  pinMode(2, INPUT_PULLUP);
  pinMode(3, INPUT_PULLUP);
  pinMode(4, OUTPUT);
  
  attachInterrupt(0, sw1, FALLING);
  attachInterrupt(1, sw2, FALLING);
  //S1
  sv1.attach(9, 618, 2445, 180);
  //S2
  sv2.attach(10, 655, 2620, 180);
  //S3
  sv3.attach(11, 655, 2250, 180);
  Serial.begin(9600);
}
String val;
int count = 0;
void loop()
{
  count ++;
  char dataHead = Serial.read();
  if(dataHead == 's'){
    //サーボモード
    val = Serial.readStringUntil('\n');
    sv1r = val.toFloat();
    val = Serial.readStringUntil('\n');
    sv2r = val.toFloat();
    val = Serial.readStringUntil('\n');
    sv3r = val.toFloat();
    val = Serial.readStringUntil('\n');
    requestVolume = val.toInt() > 0;
    val = Serial.readStringUntil('\n');
    led1 = val.toInt() > 0;
    val = Serial.readStringUntil('\n');
    led2 = val.toInt() > 0;
    
    count = 0;
  }
  if(0 > sv1r || sv1r > 180){
    count = 120;
  }
  if(0 > sv2r || sv2r > 180){
    count = 120;
  }
  
  if(count > 100){
    sv1r = 0;
    sv2r = 0;
    sv3r = 90;
  }
  if(requestVolume){
     //vol
    Serial.write('v');
    Serial.println(analogRead(0));
  }
  
  sv1.write(180-sv1r);
  sv2.write(180-sv2r);
  sv3.write(sv3r);
  digitalWrite(12, led1?HIGH:LOW);
  digitalWrite(13, led2?HIGH:LOW);

  sendToClient();
  sw1Pressed = sw2Pressed = false;
}

void sendToClient()
{
  //vol
  //Serial.write('v');
  //Serial.println(analogRead(0));
  //led
  Serial.write('l');
  Serial.println(analogRead(1));

  Serial.write('1');
  Serial.println(sw1Pressed?"1":"0");

  Serial.write('2');
  Serial.println(sw2Pressed?"1":"0");
}

void sw1()
{
  if(millis() - swt < 100) return;
  swt = millis();
  sw1Pressed = true;
}

void sw2()
{
  if(millis() - swt < 100) return;
  swt = millis();
  sw2Pressed = true;
}
