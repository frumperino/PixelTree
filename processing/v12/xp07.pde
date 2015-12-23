class XP07 extends LEDpattern2D
{
  ArrayList<Beam> beams;
  color c1 = color(255,0,0);
  int numBeams = 6;

  public XP07()
  {
    super("Radial1", createGraphics(320,320,P2D),true);
    ppg.beginDraw();
    ppg.background(0xFF000000);
    ppg.endDraw();
    beams = new ArrayList<Beam>();
    for (int i=0;i<numBeams;i++)
    {
      beams.add(new Beam(i));
    }
  }
  
  public void start() {}
  public void stop() {}

  public void draw2D()
  {
    ppg.beginDraw();
    ppg.background(0x00);
    ppg.blendMode(ADD);
    ppg.scale(160,160);
    ppg.translate(1,1);
    for (Beam b:beams)
    {
      b.draw();
    }
    ppg.blendMode(BLEND);
    ppg.endDraw();
  }
  
  class Beam
  {
    float phase = 0;
    float speed = 0;
    float size = 1;
    color c;
    
    public Beam(int i)
    {
      phase = random(360);
      speed = random(100)/50;
      size = random(100)/50;
      c = 0xFF000000 | hsl2rgb(600+i * 40,255,255);
    }
    
    public void draw()
    {
      phase += speed;
      ppg.fill(c);
      ppg.noStroke();
      ppg.pushMatrix();
      ppg.rotate(radians(phase));
      ppg.triangle(0,0,-size,4,size,4);
      ppg.triangle(0,0,-size,-4,size,-4);
      ppg.popMatrix();
    }
  }
  
}