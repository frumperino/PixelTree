class XP06 extends LEDpattern2D
{
  public XP06()
  {
    // the LEDpattern2D parent class 
    super("Camera", createGraphics(480,240,P2D),false);
    ppg.beginDraw();
    ppg.background(0xFF000000);
    ppg.endDraw();
  }
  
  public void start() {}
  public void stop() {}
  
  public void draw2D()
  {
    if ((camera != null) && (camera.available()))
    {
      ppg.beginDraw();
        camera.read();
        ppg.image(camera,0,0,ppg.width,ppg.height);
      ppg.endDraw();
    }
  }
}