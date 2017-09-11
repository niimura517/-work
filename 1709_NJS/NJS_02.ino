
/* This example shows how to get single-shot range
 measurements from the VL53L0X. The sensor can optionally be
 configured with different ranging profiles, as described in
 the VL53L0X API user manual, to get better performance for
 a certain application. This code is based on the four
 "SingleRanging" examples in the VL53L0X API.
 The range readings are in units of mm. */

#include "I2Cdev.h"
//#include <Wire.h> //I2C用ライブラリ
#include <VL53L0X.h>
#include <Adafruit_NeoPixel.h>
#include <Servo.h>
#include <wiring_private.h> //sbi, cbiのはいったライブラリ
#include <MsTimer2.h>

/* Arduino Wire library is required if I2Cdev I2CDEV_ARDUINO_WIRE implementation
  is used in I2Cdev.h */
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
  #include "Wire.h"
#endif

// RGBLEDに出力するピン番号
#define RGBLED_OUTPIN    8
// Arduinoにぶら下がっているRGBLEDの個数
#define NUMRGBLED        1

// RGBLEDのライブラリを生成する(色指定はRGBの並びで行う、LEDの速度は800KHzとする)
Adafruit_NeoPixel RGBLED = Adafruit_NeoPixel(NUMRGBLED, RGBLED_OUTPIN, NEO_RGB + NEO_KHZ800);

VL53L0X sensor;
float dist;
const unsigned int Max_dist = 200; //200cm 以上は測定範囲外

/*  Uncomment this line to use long range mode. This
	increases the sensitivity of the sensor and extends its
	potential range, but increases the likelihood of getting
	an inaccurate reading because of reflections from objects
	other than the intended target. It works best in dark
	conditions. */

//#define LONG_RANGE

// Uncomment ONE of these two lines to get
// - higher speed at the cost of lower accuracy OR
// - higher accuracy at the cost of lower speed

//#define HIGH_SPEED
#define HIGH_ACCURACY

// 前方障害物検出用超音波センサ
#define TRIG_PIN 1	// IN5_P2.1
#define ECHO_PIN 2	// IN6_P2.0

//Servoオブジェクトを作成

Servo sv;

#define SERVO1 5

//void full_stop()  {
//	analogWrite(SERVO1,0);
//}

int front_sense() {
	int duration, distance;
	//
	digitalWrite(TRIG_PIN,LOW);
	delayMicroseconds(2);
	digitalWrite(TRIG_PIN,HIGH);
	delayMicroseconds(10);
	digitalWrite(TRIG_PIN,LOW);
	duration = pulseIn(ECHO_PIN,HIGH);  
	if (duration>0) {
		distance = duration/2;
		distance = distance*340*100/1000000; 
		Serial.print(duration);
		Serial.print(" us ");
		Serial.print(distance);
		Serial.println(" cm");
		}
	delay(50);  // Wait 500mS before next ranging
}

#define SW_SERVO 7
#define START_PIN 12

#define SWITCH_ON HIGH
#define SWITCH_OFF LOW

int value = 0;
int mode = 0;

int RWD_L = 9;	// IN1_P1.2
int FWD_L = 3;	// IN2_P1.3
int FWD_R = 11;	// IN3_PI.6
int RWD_R = 10;	// IN4_PI.7


void setup(){

// join I2C bus (I2Cdev library doesn't do this automatically)
	#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
		Wire.begin();  // マスターとする
	#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
		Fastwire::setup(400, true);
	#endif

	Serial.begin(9600);

	pinMode(SW_SERVO, OUTPUT);
	pinMode(START_PIN, INPUT_PULLUP);

	RGBLED.begin() ;         // RGBLEDのライブラリを初期化する
	RGBLED.setBrightness(100) ;    // 明るさの指定(0-255)を行う
	RGBLED.setPixelColor(0, 0,0,0) ; // LED OFF(R=0,G=0,B=0)
	RGBLED.show() ;          // LEDにデータを送り出す

	sensor.init();
	sensor.setTimeout(500);

	#if defined LONG_RANGE
	// lower the return signal rate limit (default is 0.25 MCPS)
		sensor.setSignalRateLimit(0.1);
	// increase laser pulse periods (defaults are 14 and 10 PCLKs)
		sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodPreRange, 18);
		sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodFinalRange, 14);
	#endif

	#if defined HIGH_SPEED
	// reduce timing budget to 20 ms (default is about 33 ms)
		sensor.setMeasurementTimingBudget(20000);
	#elif defined HIGH_ACCURACY
	// increase timing budget to 200 ms
		sensor.setMeasurementTimingBudget(200000);
	#endif

	pinMode(TRIG_PIN, OUTPUT);
	pinMode(ECHO_PIN, INPUT);

	pinMode(RWD_L,OUTPUT);
	pinMode(FWD_L,OUTPUT);
	pinMode(FWD_R,OUTPUT); 
	pinMode(RWD_R,OUTPUT);

	sbi(TCCR0B, CS02);
	cbi(TCCR0B, CS01);
	sbi(TCCR0B, CS00);

	/* CS02 CS01  CS00  意味
		0    0   0   クロックなし
		0    0   1   分周比1
		0    1   0   分周比8
		0    1   1   分周比64 ← default
		1    0   0   分周比256
		1    0   1   分周比1024
		1    1   0   外部クロック。立ち下がりでオン
		1    1   1   外部クロック。立ち上がりでオン */
         
	// #5, #6に対応するタイマ/カウンタ0が使用するTCCR0Bレジスタの値を変更して分周比を1024にする。
	// cbiはレジスタの対応するビットを'0'に、sbiは'1'にする。
	// サーボモーター周期は16.38ms(61.035Hz) (周期 = クロック周波数(16MHz)÷(分周比(1024) x 256))

	//  servo1.attach(SERVO1, 800, 2300); //SERVO1(5)ピンをサーボの信号線として設定
	pinMode(SERVO1, OUTPUT);

}


void loop(){

//	full_stop();

//	int tmp_cnt;	// 拮抗処理用カウンタ
	
//サーボモーター動作確認用
/*	シリアルモニターからサーボを操作
	r: サーボ値読み取り
	0-9: 角度(0~90度)設定
	a: attach(5)
	d: detatch()	*/

	int ret;
		if (Serial.available() > 0)	{
			int d = Serial.read();
			if (d == 'a') {
				sv.attach (5, 800, 2200);
			}
			else if (d == 'd')	{
				sv.detach();
			}
			else if (d == 'r')	{
				Serial.println (sv.read());
			}
			else if ('0' <= d && d <= '9')	{
				int angle = (d - '0') * 10;
				sv.write(angle);
			}
		}
	
	while (1) {
		if (digitalRead(START_PIN)==LOW) break;
	}

	dist = sensor.readRangeSingleMillimeters()/10.0 + 0.1; // 単位を"cm”に変換 + 補正

	int sum_d = 0;
	int v_sum_n = 0;
	while(v_sum_n < 5){
		sum_d = sum_d + (dist);
		v_sum_n = v_sum_n +1;
	}
	value = sum_d / 5;
	Serial.print(value); 
	Serial.print("\t");   // (改行)タブを送信
	Serial.println();   

	if (value <= 20){
		move_stop(3);
		analogWrite(SERVO1,16); // PWM出力。(デューティー(Hi): 1023.75us)
		delayMicroseconds(1000);
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 255,0,0);
		RGBLED.show();
	}
	else if (value > 20 && value < 100){
		move_stop(1);
		analogWrite(SERVO1,19); // PWM出力。(デューティー(Hi): 1215.70us)
		delayMicroseconds(1000);
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 0,255,0);
		RGBLED.show();
	}
	else if (value >= 100 && value < 200){
		move_stop(1);
		analogWrite(SERVO1,22); // PWM出力。(デューティー(Hi): 1407.66us)
		delayMicroseconds(1000);;
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 0,0,255);
		RGBLED.show();
	}
	else{
		move_forward();
		analogWrite(SERVO1,24); // PWM出力。(デューティー(Hi): 1535.63us)
		delayMicroseconds(1000);;
		digitalWrite(SW_SERVO, SWITCH_OFF);
		RGBLED.setPixelColor(0, 0,0,0);
		RGBLED.show();
	}

delay(10);
}

//関数の定義

	//前進
	void move_forward(){	
		digitalWrite(RWD_R,LOW);     
		analogWrite(FWD_R,100);
		digitalWrite(RWD_L,LOW);
		analogWrite(FWD_L,100);
		//delay(ms);  
	}

	//後進
	void move_back(int ms){	
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_R,HIGH);
		digitalWrite(FWD_L,LOW);
		digitalWrite(RWD_L,HIGH);
		delay(ms);
	}

	// 左旋回
	void move_left(int ms){	
		digitalWrite(RWD_R,LOW);     
		digitalWrite(FWD_R,HIGH);
		digitalWrite(RWD_L,HIGH);
		digitalWrite(FWD_L,LOW);
		delay(ms);  
	}

	// 右旋回
	void move_right(int ms){	
		digitalWrite(RWD_R,HIGH);     
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_L,LOW);
		digitalWrite(FWD_L,HIGH);
		delay(ms);  
	}

	//停止
	void move_stop(int ms){	
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_R,LOW);
		digitalWrite(FWD_L,LOW);
		digitalWrite(RWD_L,LOW);
		delay(ms);
	}

	//シャフト動作速度制御関数
	// Servo sv;
	void moveshaft (int angle, long int delay_ms){
		int pulse = map (angle, 0, 180, 600, 2350);
		int pulse_now = sv.readMicroseconds();
			if (pulse > pulse_now) {
				for (int i = pulse_now; i <= pulse; i++) {
					sv.writeMicroseconds(i);
					delay (delay_ms);
				}
			}
			else if (pulse < pulse_now) {
				for (int i = pulse_now; i >= pulse; i--) {
					sv.writeMicroseconds(i);
					delay (delay_ms);
				}
			}
			else {	// 何もしない
			}
	}

	// 文字列を整数値に変換する関数
	int serialReadAsInt() {
		char c[ 9 ] = "0";
		for ( int i = 0; i < 8; i++ ) {
		c[ i ] = Serial.read();
		if ( c[ i ] == '\0' )
			break;
		}
		return atoi( c );
	}