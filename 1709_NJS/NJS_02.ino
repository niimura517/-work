
/* This example shows how to get single-shot range
 measurements from the VL53L0X. The sensor can optionally be
 configured with different ranging profiles, as described in
 the VL53L0X API user manual, to get better performance for
 a certain application. This code is based on the four
 "SingleRanging" examples in the VL53L0X API.
 The range readings are in units of mm. */

#include "I2Cdev.h"
//#include <Wire.h> //I2C�p���C�u����
#include <VL53L0X.h>
#include <Adafruit_NeoPixel.h>
#include <Servo.h>
#include <wiring_private.h> //sbi, cbi�̂͂��������C�u����
#include <MsTimer2.h>

/* Arduino Wire library is required if I2Cdev I2CDEV_ARDUINO_WIRE implementation
  is used in I2Cdev.h */
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
  #include "Wire.h"
#endif

// RGBLED�ɏo�͂���s���ԍ�
#define RGBLED_OUTPIN    8
// Arduino�ɂԂ牺�����Ă���RGBLED�̌�
#define NUMRGBLED        1

// RGBLED�̃��C�u�����𐶐�����(�F�w���RGB�̕��тōs���ALED�̑��x��800KHz�Ƃ���)
Adafruit_NeoPixel RGBLED = Adafruit_NeoPixel(NUMRGBLED, RGBLED_OUTPIN, NEO_RGB + NEO_KHZ800);

VL53L0X sensor;
float dist;
const unsigned int Max_dist = 200; //200cm �ȏ�͑���͈͊O

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

// �O����Q�����o�p�����g�Z���T
#define TRIG_PIN 1	// IN5_P2.1
#define ECHO_PIN 2	// IN6_P2.0

//Servo�I�u�W�F�N�g���쐬

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
		Wire.begin();  // �}�X�^�[�Ƃ���
	#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
		Fastwire::setup(400, true);
	#endif

	Serial.begin(9600);

	pinMode(SW_SERVO, OUTPUT);
	pinMode(START_PIN, INPUT_PULLUP);

	RGBLED.begin() ;         // RGBLED�̃��C�u����������������
	RGBLED.setBrightness(100) ;    // ���邳�̎w��(0-255)���s��
	RGBLED.setPixelColor(0, 0,0,0) ; // LED OFF(R=0,G=0,B=0)
	RGBLED.show() ;          // LED�Ƀf�[�^�𑗂�o��

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

	/* CS02 CS01  CS00  �Ӗ�
		0    0   0   �N���b�N�Ȃ�
		0    0   1   ������1
		0    1   0   ������8
		0    1   1   ������64 �� default
		1    0   0   ������256
		1    0   1   ������1024
		1    1   0   �O���N���b�N�B����������ŃI��
		1    1   1   �O���N���b�N�B�����オ��ŃI�� */
         
	// #5, #6�ɑΉ�����^�C�}/�J�E���^0���g�p����TCCR0B���W�X�^�̒l��ύX���ĕ������1024�ɂ���B
	// cbi�̓��W�X�^�̑Ή�����r�b�g��'0'�ɁAsbi��'1'�ɂ���B
	// �T�[�{���[�^�[������16.38ms(61.035Hz) (���� = �N���b�N���g��(16MHz)��(������(1024) x 256))

	//  servo1.attach(SERVO1, 800, 2300); //SERVO1(5)�s�����T�[�{�̐M�����Ƃ��Đݒ�
	pinMode(SERVO1, OUTPUT);

}


void loop(){

//	full_stop();

//	int tmp_cnt;	// �h�R�����p�J�E���^
	
//�T�[�{���[�^�[����m�F�p
/*	�V���A�����j�^�[����T�[�{�𑀍�
	r: �T�[�{�l�ǂݎ��
	0-9: �p�x(0~90�x)�ݒ�
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

	dist = sensor.readRangeSingleMillimeters()/10.0 + 0.1; // �P�ʂ�"cm�h�ɕϊ� + �␳

	int sum_d = 0;
	int v_sum_n = 0;
	while(v_sum_n < 5){
		sum_d = sum_d + (dist);
		v_sum_n = v_sum_n +1;
	}
	value = sum_d / 5;
	Serial.print(value); 
	Serial.print("\t");   // (���s)�^�u�𑗐M
	Serial.println();   

	if (value <= 20){
		move_stop(3);
		analogWrite(SERVO1,16); // PWM�o�́B(�f���[�e�B�[(Hi): 1023.75us)
		delayMicroseconds(1000);
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 255,0,0);
		RGBLED.show();
	}
	else if (value > 20 && value < 100){
		move_stop(1);
		analogWrite(SERVO1,19); // PWM�o�́B(�f���[�e�B�[(Hi): 1215.70us)
		delayMicroseconds(1000);
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 0,255,0);
		RGBLED.show();
	}
	else if (value >= 100 && value < 200){
		move_stop(1);
		analogWrite(SERVO1,22); // PWM�o�́B(�f���[�e�B�[(Hi): 1407.66us)
		delayMicroseconds(1000);;
		digitalWrite(SW_SERVO, SWITCH_ON);
		RGBLED.setPixelColor(0, 0,0,255);
		RGBLED.show();
	}
	else{
		move_forward();
		analogWrite(SERVO1,24); // PWM�o�́B(�f���[�e�B�[(Hi): 1535.63us)
		delayMicroseconds(1000);;
		digitalWrite(SW_SERVO, SWITCH_OFF);
		RGBLED.setPixelColor(0, 0,0,0);
		RGBLED.show();
	}

delay(10);
}

//�֐��̒�`

	//�O�i
	void move_forward(){	
		digitalWrite(RWD_R,LOW);     
		analogWrite(FWD_R,100);
		digitalWrite(RWD_L,LOW);
		analogWrite(FWD_L,100);
		//delay(ms);  
	}

	//��i
	void move_back(int ms){	
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_R,HIGH);
		digitalWrite(FWD_L,LOW);
		digitalWrite(RWD_L,HIGH);
		delay(ms);
	}

	// ������
	void move_left(int ms){	
		digitalWrite(RWD_R,LOW);     
		digitalWrite(FWD_R,HIGH);
		digitalWrite(RWD_L,HIGH);
		digitalWrite(FWD_L,LOW);
		delay(ms);  
	}

	// �E����
	void move_right(int ms){	
		digitalWrite(RWD_R,HIGH);     
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_L,LOW);
		digitalWrite(FWD_L,HIGH);
		delay(ms);  
	}

	//��~
	void move_stop(int ms){	
		digitalWrite(FWD_R,LOW);
		digitalWrite(RWD_R,LOW);
		digitalWrite(FWD_L,LOW);
		digitalWrite(RWD_L,LOW);
		delay(ms);
	}

	//�V���t�g���쑬�x����֐�
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
			else {	// �������Ȃ�
			}
	}

	// ������𐮐��l�ɕϊ�����֐�
	int serialReadAsInt() {
		char c[ 9 ] = "0";
		for ( int i = 0; i < 8; i++ ) {
		c[ i ] = Serial.read();
		if ( c[ i ] == '\0' )
			break;
		}
		return atoi( c );
	}