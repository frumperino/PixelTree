class OSD
{
  class ValuePair
  {
    String nameText;
    String valueText;
    
    public ValuePair(String name, String value)
    {
      nameText = name;
      valueText = value;
    }
  }
  PFont uiFont;
  
  ArrayList<ValuePair> data;
  
  public OSD()
  {
    uiFont = loadFont("Monospaced-12.vlw");
    data = new ArrayList<ValuePair>();
  }
  
  public void addValue(String name, String value)
  {
    data.add(new ValuePair(name,value));
  }
    
  public void draw(PGraphics p)
  {
    p.beginDraw();
    p.background(0x30);
    p.textFont(uiFont);
    p.fill(0xFF);
    int y =16;
    int x0 = 10;
    int x1 = p.width - 10;
    for (ValuePair vp:data)
    {
      p.textAlign(LEFT);
      p.text(vp.nameText,x0,y);
      p.textAlign(RIGHT);
      p.text(vp.valueText,x1,y);
      y+=14;
    }
    p.endDraw();
  }
}