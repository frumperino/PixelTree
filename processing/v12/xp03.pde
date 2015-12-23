class XP03 extends LEDpattern
{
  float[] phases = null;
  float[] speeds = null;
  boolean initialized = false;
  char[] waveform;
     
  public XP03()
  {
    super("Plasma"); // name of this pattern
  }
     
  public void start() {}
  public void stop() {}

  public void init(LEDbuffer buf)
  {
    waveform = new char[4096];
    for (int i=0;i<4096;i++)
    {
      double m = 0.5 + 0.5 * cos((float) i * 2 * PI / 4096);
      waveform[i] = (char) (m * m * 255);
    }
    int np = buf.numChains() * 3;
    phases = new float[np];
    speeds = new float[np];
    for (int i=0;i<np;i++)
    {
      phases[i] = random(6543) / 1000;
      speeds[i] = (5 + random(100)) / 8000;
    }
  }
     
  void generate(LEDbuffer buf)
  {
    if (!initialized)
    {
      init(buf);
      initialized = true;
    }
    int nc = buf.numChains();
    for (int i=0;i<nc;i++)
    {
      int cnp = buf.chainSize(i);
      int pci = i*3;
      float wmr = 80 + 80 * cos(phases[pci]);
      phases[pci] += speeds[pci];
      pci++;
      float wmg = 80 + 80 * cos(phases[pci]);
      phases[pci] += speeds[pci];
      pci++;
      float wmb = 80 + 80 * cos(phases[pci]);
      phases[pci] += speeds[pci];
      pci++;
      for (int j=0;j<cnp;j++)
      {
        float z = 100 + (float) j;
        int r = waveform[(int) (wmr * z) % 4096];
        int g = waveform[(int) (wmg * z) % 4096];
        int b = waveform[(int) (wmb * z) % 4096];
        int cm = (r << 16) | (g << 8) | b;
        buf.setPixel(i,j,cm);
      }
    }
  }
  
}