// LED system core
// Version 0.2
// 2015-11-29
// Sonny W.
// ILLUTRON

// ============================================================================
// CHAIN
// ============================================================================
// String of LEDs with same technology

class LEDchain
{
  int channelID = 0;
  int bufOffset = 0;                // offset in master buffer
  boolean bufReverse = false;       // buffer direction reversed
  int numLEDs = 100;                // number of LEDs in chain
  int[] coli;                       // requested (input) sRGB color 
  int[] colo;                       // actual (output) commanded 8-bit RGB intensity levels
  int[] error;                      // rolling error for each LED
  LEDpos[] pos;                     // LED locations
  int[] gammaLUT;                   // gamma lookup table
  double standbyCurrent = 0.35/200; // standby power consumption (per LED)
  double maxCurrent = 6.5/200;      // maximum power consumption (per LED, at full brightness)
  double gamma = 1.00;              // LED gamma (1.00 is linear - typical for WS281X)
  
  public LEDchain(int numLEDs, int channel)
  {
    this.channelID = channel;
    this.numLEDs = numLEDs;
    coli = new int[numLEDs];
    colo = new int[numLEDs];
    error = new int[numLEDs];
    pos = new LEDpos[numLEDs];
    
    setGamma(1.0);
    
    for (int i=0;i<numLEDs;i++)
    {
      coli[i] = 0; // color is black
      colo[i] = 0; // color is black
      error[i] = (int) random(0xFFFFFF);
      pos[i] = new LEDpos();
    }
  }
  
  public void setGamma(float gamma)
  {
    // assign chain LED gamma values and create sRGB compensation curve
    float ce = 2.2f / gamma; 
    gammaLUT = new int[256];
    for (int i=0;i<256;i++)
    {
      float g = pow((float) i / 255, ce);
      gammaLUT[i] = (int) floor(65536 * g);
    }
  }
  
  public void jigglePixels()
  {
     // integrate data from coli, apply gamma correction and rolling error to colo
     // (output color buffer)
     for (int i=0;i<numLEDs;i++)
     {
       int inp = coli[i];
       int igr = (brightness * gammaLUT[(inp >> 16) & 0xFF]) >> 8;
       int igg = (brightness * gammaLUT[(inp >> 8) & 0xFF]) >> 8;
       int igb = (brightness * gammaLUT[inp & 0xFF]) >> 8;
       int er = error[i];
       int err = (er >> 16) & 0xFF;
       int erg = (er >> 8) & 0xFF;
       int erb = er & 0xFF;
       int ogr = (igr >> 8) & 0xFF;
       int ogg = (igg >> 8) & 0xFF;
       int ogb = (igb >> 8) & 0xFF;
       err += (igr & 0xFF);
       erg += (igg & 0xFF);
       erb += (igb & 0xFF);
       while(err > 255) { err -= 255; ogr++; }
       while(erg > 255) { erg -= 255; ogg++; }
       while(erb > 255) { erb -= 255; ogb++; }
       colo[i] = ((ogr & 0xFF) << 16) | ((ogg & 0xFF) << 8) | (ogb & 0xFF);
       error[i] = ((err & 0xFF) << 16)|  ((erg & 0xFF) << 8) | (erb & 0xFF);
     }
  }
  
  public double getCurrent()
  {
    int aga = 0;
    int np = numLEDs;
    for (int i=0;i<numLEDs;i++)
    {
      int rgb = colo[i];
      aga += ((rgb >> 16) & 0xFF);
      aga += ((rgb >> 8) & 0xFF);
      aga += (rgb & 0xFF);
    }
    return standbyCurrent * np + (maxCurrent-standbyCurrent) * aga / 765;
  }
  
}

// ============================================================================
// ENSEMBLE
// ============================================================================
// a multi-chain installation in 3D space.

abstract class LEDensemble
{
  int numPixels;
  int offsetAssignPtr = 0;
  int[] linearPixels; // linear output data
  int[] srgbPixels;   // srgb input data
  ArrayList<LEDchain> chains;
  public LEDensemble(int numPixels)
  {
    this.numPixels = numPixels;
    chains = new ArrayList<LEDchain>();
    linearPixels = new int[numPixels];
    srgbPixels = new int[numPixels];
    offsetAssignPtr = 0;
  }
  
  public void addChain(LEDchain chain)
  {
    chains.add(chain);
    chain.bufOffset = offsetAssignPtr;
    offsetAssignPtr += chain.numLEDs;
  }

  public int numChains()
  {
    return chains.size();
  }
  
  // create buffer
  public LEDbuffer getBuffer()
  {
    return new LEDbuffer(this);
  }
  
  public void jigglePixels()
  {
    int nc = numChains();
    for (int i=0;i<nc;i++)
    {
      LEDchain c = chains.get(i);
      int cnp = c.numLEDs;
      c.jigglePixels();
      int bufo = c.bufOffset;
      for (int j=0;j<cnp;j++)
      {
        linearPixels[bufo++] = c.colo[j];
      }
    }
  }
  
  public void writePixels(LEDbuffer buf, int channel)
  {
    // only accept buffer mapped to self
    if (buf.ensemble == this)
    {
      int nc = numChains();
      for (int i=0;i<nc;i++)
      {
        LEDchain c = chains.get(i);
        if (c.channelID == channel)
        {
          int bufo = c.bufOffset;
          int cnp = c.numLEDs;
          for (int j=0;j<cnp;j++)
          {
            c.coli[j] = buf.buf[bufo++];
          }
          bufo = c.bufOffset;
          for (int j=0;j<cnp;j++)
          {
            srgbPixels[bufo++] = c.coli[j];
          }
        }
      }
    }
  }
  
  public double getCurrent()
  {
    double ac = 0;
    for (LEDchain c:chains)
    {
      ac += c.getCurrent();
    }
    return ac;
  }
  
  // draw model (2D)
  public abstract void draw(PGraphics p);

  // draw model (3D view)
  public abstract void draw3D(PGraphics p);
}


// ===========================================================
// LED BUFFER
// ===========================================================

// obtain LEDbuffer from LEDensemble object.
class LEDbuffer
{
  LEDensemble ensemble = null;
  int bufSize;
  int[] buf;
  
  public LEDbuffer(LEDensemble ens)
  {
    ensemble = ens;
    bufSize = ens.numPixels;
    buf = new int[bufSize];
  }
  
  // set color of LED in chain.
  public void setPixel(int chainIndex, int LEDindex, int col)
  {
    if ((chainIndex >= 0) && (chainIndex < ensemble.numChains()))
    {
      LEDchain c = ensemble.chains.get(chainIndex);
      if ((LEDindex >= 0) && (LEDindex < c.numLEDs))
      {
        int finalIndex = c.bufOffset + (c.bufReverse ? c.numLEDs - (1 + LEDindex) : LEDindex);
        buf[finalIndex] = col;
      }
    }
  }
  
  public int getPixel(int chainIndex, int LEDindex)
  {
    if ((chainIndex >= 0) && (chainIndex < ensemble.numChains()))
    {
      LEDchain c = ensemble.chains.get(chainIndex);
      if ((LEDindex >= 0) && (LEDindex < c.numLEDs))
      {
        int finalIndex = c.bufOffset + (c.bufReverse ? c.numLEDs - (1 + LEDindex) : LEDindex);
        return buf[finalIndex];
      }
    }
    return 0;
  }
  
  // set color of LED in ensemble
  public void setPixel(int index, int col)
  {
    if ((index >= 0) && (index < bufSize))
    {
      buf[index] = col;
    }
  }
  
  // fill buffer with color
  public void fill(int col)
  {
    for (int i=0;i<bufSize;i++)
    {
      buf[i] = col;
    }
  }
  
  public int lerp(int a, int b, int blend)
  {
    if (b > a)
    {
      int d = b-a;
      return a + (( blend * d ) >> 8);
    }
    else
    {
      int d = a-b;
      return a - (( blend * d) >> 8);
    }
  }
  
  public void lerp(LEDbuffer bufA, LEDbuffer bufB, int blend)
  {
    if ((bufA.ensemble == ensemble) && (bufB.ensemble == ensemble))
    {
      blend = (blend < 0 ? 0 : blend > 255 ? 255 : blend);
      for (int i=0;i<bufSize;i++)
      {
        int ca = bufA.buf[i];
        int cb = bufB.buf[i];
        int r = lerp((ca >> 16) & 0xFF, ((cb >> 16) & 0xFF), blend);
        int g = lerp((ca >> 8) & 0xFF, ((cb >> 8) & 0xFF), blend);
        int b = lerp(ca & 0xFF, cb & 0xFF, blend);
        buf[i] = (r << 16) | (g << 8) | b;
      }
    }
  }
  
  public LEDpos getLEDpos(int chainIndex, int LEDindex)
  {
    if ((chainIndex >= 0) && (chainIndex < ensemble.numChains()))
    {
      LEDchain c = ensemble.chains.get(chainIndex);
      if ((LEDindex >= 0) && (LEDindex < c.numLEDs))
      {
        return c.pos[LEDindex];
      }
    }
    return null;
  }
  
  public int numChains()
  {
    return ensemble.chains.size();
  }
  
  public int chainSize(int chainIndex)
  {
    return ensemble.chains.get(chainIndex).numLEDs;
  }
  
}


// ===========================================================
// LED position in 2D and 3D space
// ===========================================================

class LEDpos
{
  float x2d = 0; // virtual screen location (x)
  float y2d = 0; // virtual screen location (y)
  float x3d = 0; // physical space location (x)
  float y3d = 0; // physical space location (y)
  float z3d = 0; // physical space location (z)
  int sc = 0;    // signal source channel
}

// ===========================================================
// PATTERN SEQUENCER
// ===========================================================

class PatternSequencer
{
  int channelID = 0;
  int selectedPatternIndex = 0;
  LEDpattern selectedPattern = null;
  LEDbuffer buf1, buf2, buf3;
  
  ArrayList<LEDpattern> patterns;
  
  public PatternSequencer(LEDensemble ens, int channel)
  {
    channelID = channel;
    patterns = new ArrayList<LEDpattern>();
    buf1 = ens.getBuffer();  // pattern A
    buf2 = ens.getBuffer();  // pattern B
    buf3 = ens.getBuffer();  // output buffer
  }
  
  public void update()
  {
    if (selectedPattern != null)
    {
      selectedPattern.generate(buf3);
    }
  }
  
  LEDbuffer getBuffer()
  {
    return buf3;
  }
  
  public void addPattern(LEDpattern p)
  {
    patterns.add(p);
  }
  
  public int numPatterns()
  {
    return patterns.size();
  }
  
  public void selectPattern(int index)
  {
    if (numPatterns() > 0)
    {
      if (index < 0) index = numPatterns()-1;
      index %= numPatterns();
      if (selectedPattern != null)
      {
        selectedPattern.stop();
      }
      selectedPattern = patterns.get(index);
      selectedPattern.start();
      selectedPatternIndex = index;
    }
  }
  
  public void incrementIndex()
  {
    selectPattern(selectedPatternIndex+1);
  }
  
  public void decrementIndex()
  {
    selectPattern(selectedPatternIndex-1);
  }
  
  public void drawSelectedPattern(PGraphics p)
  {
    LEDbuffer b = buf3;
    LEDpattern pat = selectedPattern;
    p.beginDraw();
    p.noStroke();
    if (pat instanceof LEDpattern2D)
    {
      LEDpattern2D lp2 = (LEDpattern2D) pat;
      p.image(lp2.ppg,0,0,p.width,p.height);
    }
    else
    {
      p.background(0xFF333333);
    }
    p.fill(0x66000000);
    p.rect(0,0,p.width-1,p.height-1);
    int ofs = 0;
    float sw = p.width-2;
    float sh = p.height-2;
    for (int i=0;i<b.numChains();i++)
    {
      LEDchain c = b.ensemble.chains.get(i);
      if (c.channelID == channelID)
      {
        int cl = b.chainSize(i);
        for (int j=0;j<cl;j++)
        {
          LEDpos lpos = b.getLEDpos(i,j);
          int col = 0xFF000000 | b.getPixel(i,j);
          p.pushMatrix();
          p.translate(lpos.x2d * sw, sh - lpos.y2d * sh);
          p.fill(0x66000000);
          p.rect(-1,-1,4,4);
          p.fill(col);
          p.rect(0,0,2,2);
          p.popMatrix();
        }
      }
    }
    p.endDraw();
  }
  
}

// ============================================================================
// COLOR 
// ============================================================================

// hue is integer value between 0 and 1529 where 0/1529 is red, green is 510, blue is 1020.
// sextant 0 :    0 ->  254    Red <-- [Yellow]
// sextant 1 :  255 ->  509    Yellow <-- [Green]
// sextant 2 :  510 ->  764    Green <-- [Cyan]
// sextant 3 :  765 -> 1019    Cyan <-- [Blue]
// sextant 4 : 1020 -> 1274    Blue <-- [Magenta]
// sextant 5 : 1275 -> 1529    Magenta <-- [Red]

int hsl2rgb(int h, int s, int l)
{
  int r = 0;
  int g = 0;
  int b = 0;
  
  int st = h / 255; // sextant
  int sv = h - st * 255; // phase
    
  int LE = l; // solid
  int LC = ((255-s) * l) >> 8; // neutral
  int LD = (sv * (l-LC)) >> 8; // variable

  switch(st)
  {
      case 0 : // red to yellow 
      {
          r = LE;
          g = LC+LD;
          b = LC;
      }
      break;
      case 1 : // yellow to green
      {
          r = LE-LD;
          g = LE;
          b = LC;
      }
      break;
      case 2 : // green to cyan
      {
         r = LC;
         g = LE;
         b = LC+LD;
      }
      break;
      case 3: // cyan to blue
      {
         r = LC;
         g = LE-LD;
         b = LE;
      }
      break;
      case 4: // blue to magenta
      {
         r = LC+LD;
         g = LC;
         b = LE;
      }
      break;
      case 5: // magenta to red 
      {
         r = LE;
         g = LC;
         b = LE-LD;
      }
      break;
      default:
      break;
  }
  
  return ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
}


// ===========================================================
// PATTERN BASE CLASSES
// ===========================================================

abstract class LEDpattern
{
  String name = "";
  public LEDpattern (String name)
  {
    this.name = name;
  }

  abstract void generate(LEDbuffer buf);
  abstract void start();
  abstract void stop();

}
  
// 2D pattern - automatically samples 2D image for content 
// with adjustable oversampling.

abstract class LEDpattern2D extends LEDpattern
{
  int oversample = 3;
  int oversampleStep = 3;
  boolean wraparound = false;
  PGraphics ppg = null;
  
  // buffer width and height parameters
  // pattern creates PGraphics as appropriate
  public LEDpattern2D(String name, PGraphics pg, boolean wraparound)
  {
    super(name);
    ppg = pg;
    this.wraparound = wraparound;
  }
  
  void generate(LEDbuffer buf)
  {
    // invoke pattern's 2D draw function
    draw2D();
    ppg.loadPixels();
    if (oversample > 0)
    {
      int h = ppg.height - oversample * oversampleStep;
      int w = ppg.width - oversample * oversampleStep;
      int nc = buf.numChains();
      for (int i=0;i<nc;i++)
      {
         int cnp = buf.chainSize(i);
         for (int j=0;j<cnp;j++)
         {
           LEDpos lp = buf.getLEDpos(i,j);
           int y0 = (int) (h - lp.y2d * h);
           int x0;
           if (wraparound)
           {
             x0 = (int) (lp.x2d * w);
           }
           else
           {
             if (lp.x2d > 0.5)
             {
               x0 = (int) (w - (lp.x2d - 0.5) * 2 * w);
             }
             else
             {
               x0 = (int) (lp.x2d * 2 * w);
             }
           }
           int cr = 0;
           int cg = 0;
           int cb = 0;
           for (int y=0;y<oversample;y++)
           {
             for (int x=0;x<oversample;x++)
             {
               int sx = x0 + x * oversampleStep;
               int sy = y0 + y * oversampleStep;
               int cs = ppg.pixels[(sy*ppg.width)+sx];
               cr += ((cs >> 16) & 0xFF);
               cg += ((cs >> 8) & 0xFF);
               cb += (cs & 0xFF);
             }
           }
           int nn = oversample * oversample;
           cr /= nn;
           cg /= nn;
           cb /= nn;
           int co = (cr << 16) | (cg << 8) | cb;
           buf.setPixel(i,j,co);
         }
      }
    }
    else
    {
      int h = ppg.height - 1;
      int w = ppg.width - 1;
      int nc = buf.numChains();
      for (int i=0;i<nc;i++)
      {
         int cnp = buf.chainSize(i);
         for (int j=0;j<cnp;j++)
         {
           LEDpos lp = buf.getLEDpos(i,j);
           int y = (int) (h - (lp.y2d * h));
           int x;
           if (wraparound)
           {
             x = (int) (lp.x2d * w);
           }
           else
           {
             if (lp.x2d > 0.5)
             {
               x = (int) (w - (lp.x2d - 0.5) * 2 * w);
             }
             else
             {
               x = (int) (lp.x2d * 2 * w);
             }
           }
           buf.setPixel(i,j,ppg.pixels[y*ppg.width+x]);
         }
      }
    }
  }
  
  abstract void draw2D(); // pattern paints 2D 
}

class MoviePattern extends LEDpattern2D
{
  Movie movie;
  String videoFileName;
  public MoviePattern(String patternName, String videoFileName, boolean seamless)
  {
    super(patternName, createGraphics(480,320,P2D), seamless);
    this.videoFileName = videoFileName;
  }
  
  public void start()
  {
    movie = new Movie(getPap(),videoFileName);
    movie.loop();
  }
  
  public void stop()
  {
    movie.stop();
  }

  public void draw2D()
  {
    ppg.beginDraw();
    if (movie.available())
    {
      movie.read();
      ppg.image(movie,0,0,ppg.width,ppg.height);
    }
    ppg.endDraw();
  }

}