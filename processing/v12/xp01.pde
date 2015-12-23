// pretty basic pattern
// pulsating strings

class XP01 extends LEDpattern
{
  
  public XP01 ()
  {
    super("Pulsator"); // name of this pattern
  }
  
  public void start() {}
  public void stop() {}
  
  int ho = 0; // hue offset
  
  void generate(LEDbuffer buf)
  {
    int nc = buf.numChains();
    ho++;
    for (int i=0;i<nc;i++)
    {
      int cnp = buf.chainSize(i);
      int hue = ho + (int) i * 1530 / nc;
      color rgb = hsl2rgb(hue % 1530,255,255);
      color black = (color) 0;
      int nl = cnp - 1;
      float k = (0.5 + 0.5 * sin((float) ho / 40))/ nl;
      for (int j=0;j<cnp;j++)
      {
        // use the LEDchain object to paint a pixel to the buffer
        buf.setPixel(i,j,lerpColor(black,rgb,(float) j * k));
      }
    }
  }
}