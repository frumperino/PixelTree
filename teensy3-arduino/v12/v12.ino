#include <OctoWS2811.h>
#include "typedefs.h"

#define __switchOverride // comment out if mode control switches are present

const int octoStripLength = 200;
DMAMEM int octoDisplayMemory[octoStripLength*6];
int octoDrawingMemory[octoStripLength*6];
const int octoConfig = WS2811_RGB | WS2811_800kHz;

OctoWS2811 octo(octoStripLength, octoDisplayMemory, octoDrawingMemory, octoConfig);

// _________________________________
// Main task scheduler stuff

#define _numTasks 4
#define _standbyVidHz 90   // standby video scan rate
#define _timeout 500       // video timeout
#define _timeoutCheckHz 10 //
#define _serialHz 300      //

// ---------------------------------------------------

#define _vidChains 8   // chain count
#define _vidLength 200 // chain length
#define _vidPixels     (_vidChains * _vidLength) 

unsigned int TlastFrame = 0;

void timeOutTask(int arg)
{
  unsigned int Tnow = millis();
  if (Tnow - TlastFrame >= _timeout)
  {
    goStandby();
  }
}

int operMode = 0;

void goStandby()
{
  operMode = 0; // 0 means standby
  clearTask(0);
  scheduleTask(2, &standbyTask, _standbyVidHz, 0); // engage standby pattern
}

void goLive()
{
  operMode = 1; // 1 means live
  TlastFrame = millis(); // now
  clearTask(2); // halt standby pattern
  scheduleTask(0, &timeOutTask, _timeoutCheckHz, 0); // check for timeout
}

void setup() 
{
  octo.begin();
  Serial.begin(256000); 
  initTasks();
  fastSinSetup();
  stb_init();
  goLive();
  scheduleTask(1, &serialTask, _serialHz, 0); // check serial port
  scheduleTask(3, &blinkTask, 2, 0); // blink it
  pinMode(13,OUTPUT);
}

void loop() 
{
  checkTasks();
}

void blinkTask(int arg)
{
  digitalWrite(13, 1^digitalRead(13));
}

// ---------------------------------------------------

