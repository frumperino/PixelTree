class XP02 extends LEDpattern
{
  int hp = 0;
  
  public XP02()
  {
    super("Rainbow sparkle"); // name of this pattern
  }
    
  public void start() {}
  public void stop() {}
     
  void generate(LEDbuffer buf)
  {
    hp+=19;
    int nc = buf.numChains();
    for (int i=0;i<nc;i++)
    {
      int cnp = buf.chainSize(i);
      for (int j=0;j<cnp;j++)
      {
        buf.setPixel(i,j,hsl2rgb((j*15+hp) % 1530, 255, random(10) < 1 ? 255 : 0));
      }
    }
  }
  
}