class XP05 extends LEDpattern2D
{
  public XP05()
  {
    super("Candystripe", createGraphics(512,256,P2D),true);
    ppg.beginDraw();
    ppg.background(0xFF000000);
    ppg.endDraw();
  }
  
  public void start() {}
  public void stop() {}

  color c1 = color(255,0,0);
  color c2 = color(255,255,255);
  int numStripes = 3;
  int stripeSpeed = 7;
  int stripePhase = 0;
  
  public void draw2D()
  {
    ppg.beginDraw();
    ppg.background(c1);
    ppg.noStroke();
    ppg.fill(c2);
    float sx = (float) ppg.width / (numStripes * 2);
    float ox = -sx * (2 - (float) stripePhase / 500);
    for (int i=0;i<numStripes+1;i++)
    {
      ppg.rect(ox+i*sx*2,0,sx,ppg.height);
    }
    ppg.endDraw();
    stripePhase+= stripeSpeed;
    stripePhase %= 1000;
  }
}