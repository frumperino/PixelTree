static String serialPortName = null;  // no serial (offline mode)
// static String serialPortName = "/dev/tty.usbmodem512801";  
// static String serialPortName = "/dev/tty.usbmodem1290961";  

static float ledHz = 150;         // asynchronous LED chain refresh rate (completely independent of other timer tasks.)
static int meterHz = 30;          // number of integrating meter updates per second (also asynchronous)

// the occurrence of these tasks are all derived from videoHz.
static int videoHz = 60;          // processing sketch screen refresh rate. 
static int monitorCadence = 2;    // repaint 3D monitor 20 times per second
static int uiCadence = 30;        // update UI 3 times per second
static int patternCadence = 2;    // update pattern 60 times per second

static int brightnessStep = 10;   // manual brightness increment and decrement by this step value (in 8-bit scale)
int brightness = 255;             // initial output brightness (applied in the gamma correction pixel jiggle function)

double supplyVolts = 12.5 ;        // supply voltage (insert sensor signal here later) 
double auxLoadWatts = 40 ;         // 40W aux load (laptop, etc)

LEDensemble ensemble;             // chain layout
PatternSequencer sq1;             // tree pattern sequencer
PatternSequencer sq2;             // crown pattern sequencer
PowerMeter meter;                 // power minder
Capture camera;                   // video capture device
Serial serial;                    // serial port
OSD osd;                          // OSD overlay with stats
Timer timer1;                     // main pattern timer
Timer timer2;                     // meter timer
PGraphics grOSD;                  // dashboard overlay
PGraphics ev3D;                   // 3D ensemble view
PGraphics pv1;                    // pattern viewer 1
PGraphics pv2;                    // pattern viewer 1
LEDbuffer buf;

void setup()
{
  size(1024,600,P2D);
  smooth(1);
  appSetup();
  // the patterns
  sq1.addPattern(new MoviePattern("fire","fire.mov",true)); // 0 - fire
  sq1.addPattern(new XP01()); // 1 - pulsator
  sq1.addPattern(new XP02()); // 2 - color sparkles
  sq1.addPattern(new XP03()); // 3 - RGB plasma
  sq1.addPattern(new XP04()); // 4 - vertical bars
  sq1.addPattern(new XP05()); // 5 - candy stripes
  sq1.addPattern(new XP06()); // 6 - camera 
  // sequencer.addPattern(new MoviePattern("Green Lava","lavalamp.mov",false)); // 7 - lava lamp
  // sequencer.addPattern(new MoviePattern("aquarays","aquarays.mov",false)); // 10 - aqua rays
  sq1.selectPattern(0);
  
  sq2.addPattern(new MoviePattern("CV021","cv021.mov",true)); // 8 - pink rectangles
  sq2.addPattern(new XP03());
  sq2.addPattern(new XP07());
  sq2.selectPattern(2);
}