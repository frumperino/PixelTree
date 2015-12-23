class XP04 extends LEDpattern2D
{
  int numBars = 10;
  
  public XP04()
  {
    super("V-bars", createGraphics(256,512,P2D),true);
    ppg.beginDraw();
    ppg.background(0xFF000000);
    ppg.endDraw();
    bars = new Bar[numBars];
    for (int i=0;i<numBars;i++)
    {
      bars[i] = new Bar();
    }
  }
  
  public void start() {}
  public void stop() {}
  
  Bar[] bars;
  
  public void draw2D()
  {
    float w = ppg.width;
    float h = ppg.height;
    ppg.beginDraw();
    ppg.background(0x00);
    ppg.noStroke();
    for (int i=0;i<numBars;i++)
    {
      bars[i].move();
      bars[i].draw();
    }
    ppg.endDraw();
  }
  
    class Bar
  {
    float yp;
    float ys;
    float yh;
    color c;
    public Bar()
    {
      init();
    }
    
    public void init()
    {
      ys = 1+random(5);
      yh = 4+random(30);
      yp = -yh;
      c = 0xFF000000 | hsl2rgb((int) random(1530), 255, 255);
    }
    
    public void move()
    {
      yp += ys;
      if (yp > ppg.height)
      {
        init();
      }
    }
    
    public void draw()
    {
      ppg.fill(c);
      ppg.rect(0,yp,ppg.width,yh);
    }
  }
}