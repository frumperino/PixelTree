import java.util.Timer;
import java.util.TimerTask;
import processing.serial.*;
import processing.video.*;

PApplet getPap()
{
  return this;
}

// ==================================================
// POWER MANAGEMENT
// ==================================================

double treeAmperes = 0 ;           // instant tree ampere load
double treeWatts = 0 ;             // 
double totalWatts = 0 ;            // total power draw
double totalAmperes = 0;          
class MeterTimerTask extends TimerTask
{
  public void run()
  {
    treeAmperes = ensemble.getCurrent();
    treeWatts = supplyVolts * treeAmperes;
    totalWatts = treeWatts + auxLoadWatts;
    totalAmperes = totalWatts / supplyVolts;
    meter.integrateLoad(totalWatts);
  }
}

// ==================================================
// BRIGHTNESS CONTROL
// ==================================================

void brightIncrease()
{
  brightness += brightnessStep;
  if (brightness > 255) brightness = 255;
}

void brightDecrease()
{
  brightness -= brightnessStep;
  if (brightness  < 0) brightness = 0;
}

// =========================================
// SERIAL OUTPUT
// =========================================

byte[] txBuf;

void streamOut(Serial s, LEDensemble ens)
{
  if ((s != null) && (s.active()))
  {
    if (txBuf == null)
    {
      txBuf = new byte[ens.numPixels*3+2];
      txBuf[0] = (byte) 0x55;  // sync mark 1
      txBuf[1] = (byte) 0xAA;  // sync mark 2
    }
    int j = 2;
    for (int i=0;i<ens.numPixels;i++)
    {
      int col = ens.linearPixels[i];
      txBuf[j++] = (byte) ((col >> 16) & 0xFF); // red
      txBuf[j++] = (byte) ((col >> 8) & 0xFF); // green
      txBuf[j++] = (byte) (col & 0xFF); // blue
    }
    s.write(txBuf);
  }
}

// ==================================================
// OSD REFRESH
// ==================================================

long tLastDraw;    // time of last UI update
long lfcLastDraw;  // LED frame count at last display update

void updateOSD()
{
    osd.data.clear();

    // fps indicator  
    long Tnow = millis();
    long Td = Tnow - tLastDraw; // millis between stat updates
    double ds = (double) Td / 1000;
    int frd = (int) (fcled - lfcLastDraw);
    double fps = (double) frd / ds;
    lfcLastDraw = fcled;
    tLastDraw = Tnow;
    osd.addValue("Pattern-T:",sq1.selectedPattern.name);
    osd.addValue("Pattern-C:",sq2.selectedPattern.name);
    osd.addValue("Frame:",Long.toString(fcled));
    osd.addValue("FPS:",String.format("%.2f",fps));
    
    // power management
    double ah = meter.getAH(supplyVolts);
    double wh = meter.getWH();
    osd.addValue("Bat volts:",String.format("%.2f",(float)supplyVolts));
    osd.addValue("Tree load (A):",String.format("%.2f",(float)treeAmperes));
    osd.addValue("Tree load (W):",String.format("%.2f",(float)treeWatts));
    osd.addValue("Aux load (W):",String.format("%.2f",(float)auxLoadWatts));
    osd.addValue("Total load (A):",String.format("%.2f",(float)totalAmperes));
    osd.addValue("Total load (W):",String.format("%.2f",(float)totalWatts));
    osd.addValue("Amp hours:",String.format("%.2f",(float)ah));
    osd.addValue("Watt hours:",String.format("%.2f",(float)wh));
    osd.addValue("Brightness (%)",String.format("%.1f",(float)brightness / 2.55));

    osd.draw(grOSD);
}

// ==================================================
// KEYBOARD CONTROL
// ==================================================

void keyPressed()
{
  if (key == CODED)
  {
    switch(keyCode)
    {
      case UP : { brightIncrease(); } break;
      case DOWN: { brightDecrease(); } break;
      case LEFT: { sq1.decrementIndex(); } break;
      case RIGHT: { sq1.incrementIndex(); } break;
      case CONTROL: { sq2.decrementIndex(); } break;
      case SHIFT: { sq2.incrementIndex(); } break;
    }
 }
 updateOSD();
}

// ==================================================
// <PROCESSING> REFRESH DISPLAY AND PATTERN ITERATION
// ==================================================

int fcdis = 0; // display frame counter
void draw()
{
  // update text fields every 4 video frames
  if ((fcdis % uiCadence) == 0) { updateOSD(); }
  if ((fcdis % patternCadence) == 0) { updatePattern(); };
  if ((fcdis % monitorCadence) == 0) { ensemble.draw3D(ev3D); };
  background(0x00); 
  image(ev3D,200,0);
  image(grOSD,0,0);
  image(pv1,500,0);
  image(pv2,500,300);
  fcdis++;
}

// ==================================================
// PAINT THE PATTERN
// ==================================================

int fcled = 0; // LED frame counter
void updatePattern()
{
  sq1.update();
  sq2.update();
  ensemble.writePixels(sq1.getBuffer(),1);
  ensemble.writePixels(sq2.getBuffer(),2);
  sq1.drawSelectedPattern(pv1);
  sq2.drawSelectedPattern(pv2);
  fcled++;
}

// ==================================================
// SEND TO LEDS
// ==================================================

class LEDrefreshTimerTask extends TimerTask
{
  public void run()
  {
    ensemble.jigglePixels();
    streamOut(serial, ensemble);
  }
}

// =========================================
// SKETCH SETUP
// =========================================

void appSetup()
{
  if (serialPortName != null) { serial = new Serial(this,serialPortName); } // start the serial port if it has been declared.
  frameRate(videoHz);                           // monitor window refresh rate 
  camera = new Capture(this);  camera.start();  // remove this if none of the patterns are using video capture.
  meter = new PowerMeter();                     // energy consumption meter
  ensemble = new XmasTree2015();                // see tree tab for configuration details.
  buf = ensemble.getBuffer();                   // grab LED buffer from tree model
  sq1 = new PatternSequencer(ensemble,1);       // tree
  sq2 = new PatternSequencer(ensemble,2);       // crown
  osd = new OSD();
  grOSD = createGraphics(200,600,P2D);
  ev3D = createGraphics(300,600,P3D);
  pv1 = createGraphics(500,300,P2D);
  pv2 = createGraphics(500,300,P2D);
  timer1 = new Timer();
  timer1.scheduleAtFixedRate(new LEDrefreshTimerTask(), 0, (long) (1000f / ledHz)); 
  timer2 = new Timer();
  timer2.scheduleAtFixedRate(new MeterTimerTask(), 0, (long) (1000f / meterHz)); 
}

// =========================================
// SKETCH SHUTDOWN
// =========================================

void stop()
{
  timer1.cancel();
  timer2.cancel();
}