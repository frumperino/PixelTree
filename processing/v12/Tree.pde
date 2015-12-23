// the christmas tree 
// LEDensemble configuration specific 
// to the 2015 Illutron Floating Christmas Tree in the Copenhagen Harbor
// as described here:
// http://www.maximise.dk/the-high-tech-floating-christmas-tree/

class XmasTree2015 extends LEDensemble
{
  
  public XmasTree2015()
  {
    super(1600); // composition with 1600 LEDs.
    for (int i=0;i<12;i++)
    {
      LEDchain c = new LEDchain(100,1); // 100 pixels in each chain
      c.bufReverse = (i & 0x01) > 0; // every other chain reversed.
      addChain(c);
      mapCone(c,i);
    }
    LEDchain cPentacle = new LEDchain(200,2);
    addChain(cPentacle);
    LEDchain cCircle = new LEDchain(200,2);
    addChain(cCircle);
    mapCrown(cPentacle, cCircle);
  }

  float rotationSpeed = 0.45;
  
  class ConeCoordinate
  {
    float coneRadiusUpper3D = 0.04;
    float coneRadiusLower3D = 0.20;
    
    float coneRadiusDelta3D = coneRadiusLower3D - coneRadiusUpper3D;
    float coneHeight3D = 0.7;
    
    float h; // height (0..1)
    float a; // angle (0..360)
    public ConeCoordinate(float height, float angle)
    {
      a = angle;
      while (a >= 360)
      {
        a-= 360;
      }
      while (a < 0)
      {
        a+= 360;
      }
      this.h = (height < 0 ? 0 : height > 1 ? 1 : height);
    }
    
    public LEDpos getLEDpos()
    {
      LEDpos lp = new LEDpos();
      lp.x2d = a / 360;
      if (lp.x2d < 0) { lp.x2d += 1; }
      if (lp.x2d >= 1) { lp.x2d -= 1; }
      lp.y2d = h;
      lp.y3d = h * coneHeight3D;
      float r = coneRadiusUpper3D + (1 - h) * coneRadiusDelta3D;
      lp.x3d = r*cos(radians(a));
      lp.z3d = r*sin(radians(a));
      return lp;
    }
  }
  
  void mapCone(LEDchain c, int chainIndex)
  {
    // these numbers are conical coordinates and describe the path for a single chain in the tree.
    // the first number in each coordinate is height off ground on a range from 0..9
    // the second is the longitudinal angle. 
    // there are 11 coordinates, describing 10 linear interpolated segments, each with 10 LEDs,
    // in a 100-LED chain. there are 6 "clockwise" and 6 "anti-clockwise" chains in the tree,
    // alternating along the radial axis.
    // the "anti-clockwise" chains are simply mirror images of the clockwise chains.
    float[] coords = {
    0,   190,
    0.6, 167,
    1.3, 143,
    2.0, 116,
    2.8, 88,
    3.7, 62,
    4.6, 36,
    5.7, 14,
    6.9, 2,
    8.0, 0,
    9.0, 0,
    };
    
    int pidx = 0;
    for (int i=0;i<10;i++)
    {
      float a0,a1,ad,h0,h1,hd;
      int o = i<<1;
      float ao = chainIndex * 30;
      h0 = coords[o++] / 9;
      a0 = coords[o++];
      h1 = coords[o++] / 9;
      a1 = coords[o++];
      hd = (h1 - h0) / 10;
      ad = (a1 - a0) / 10;
      if ((chainIndex & 0x01) > 0)
      {
        for (int j=0;j<10;j++)
        {
          ConeCoordinate cc = new ConeCoordinate(h0+j*hd,ao-(a0+j*ad));
          LEDpos lp = cc.getLEDpos();
          c.pos[pidx++] = lp;
        }
      }
      else
      {
        for (int j=0;j<10;j++)
        {
          ConeCoordinate cc = new ConeCoordinate(h0+j*hd,ao+a0+j*ad);
          LEDpos lp = cc.getLEDpos();
          c.pos[pidx++] = lp;
        }
      }
    }
  }

  void lerpMap(LEDchain c, LEDpos p0, LEDpos p1, int index0, int index1)
  {
    int ic = index1 - index0;
    if (ic > 0)
    {
      float ds = 1 / (float) (ic - 1);
      for (int i=0;i<ic;i++)
      {
        LEDpos p = new LEDpos();
        float w = ds * i;
        p.x2d = p0.x2d + w * (p1.x2d - p0.x2d);
        p.y2d = p0.y2d + w * (p1.y2d - p0.y2d);
        p.x3d = p0.x3d + w * (p1.x3d - p0.x3d);
        p.y3d = p0.y3d + w * (p1.y3d - p0.y3d);
        p.z3d = p0.z3d + w * (p1.z3d - p0.z3d);
        c.pos[index0+i] = p;
      }
    }
  }

  void mapCrown(LEDchain pentacle, LEDchain circle)
  {
    float crownCenterHeight3D = 0.90;
    float penta3Dradius = 0.10;
    float penta2Dradius = 0.35;
    float pentaFirstAngle = 13 * 360 / 20;
    float circle3DradiusOuter = 0.10;
    float circle3DradiusInner = 0.09;
    float circle2DradiusOuter = 0.45;
    float circle2DradiusInner = 0.25;
    float circleThickness3D = 0.015;
    float pentaThickness3D = 0.03;
    
    // nearside outer circle
    for (int i=0;i<48;i++)
    {
      float v1 = radians(270 - 360 * (float) i / 48); 
      float v2 = radians(90 + 360 * (float) i / 48); 
      LEDpos p = new LEDpos();
      p.x2d = 0.50 + circle2DradiusOuter * cos(v1);
      p.y2d = 0.50 + circle2DradiusOuter * sin(v1);
      p.x3d = 0.00 + circle3DradiusOuter * cos(v2);
      p.y3d = crownCenterHeight3D + circle3DradiusOuter * sin(v2);
      p.z3d = circleThickness3D / 2;
      circle.pos[i] = p;
    }
    // farside outer circle
    for (int i=0;i<48;i++)
    {
      float v1 = radians(270 - 360 * (float) i / 48); 
      float v2 = radians(90 + 360 * (float) i / 48); 
      LEDpos p = new LEDpos();
      p.x2d = 0.50 + circle2DradiusOuter * cos(v1);
      p.y2d = 0.50 + circle2DradiusOuter * sin(v1);
      p.x3d = 0.00 + circle3DradiusOuter * cos(v2);
      p.y3d = crownCenterHeight3D + circle3DradiusOuter * sin(v2);
      p.z3d = -circleThickness3D / 2;
      circle.pos[i+49] = p;
    }

    // nearside inner circle
    for (int i=0;i<45;i++)
    {
      float v1 = radians(270 - 360 * (float) i / 45); 
      float v2 = radians(90 + 360 * (float) i / 45); 
      LEDpos p = new LEDpos();
      p.x2d = 0.50 + circle2DradiusInner * cos(v1);
      p.y2d = 0.50 + circle2DradiusInner * sin(v1);
      p.x3d = 0.00 + circle3DradiusInner * cos(v2);
      p.y3d = crownCenterHeight3D + circle3DradiusInner * sin(v2);
      p.z3d = circleThickness3D / 2;
      circle.pos[i+100] = p;
    }

    // farside inner circle
    for (int i=0;i<45;i++)
    {
      float v1 = radians(270 - 360 * (float) i / 45); 
      float v2 = radians(90 + 360 * (float) i / 45); 
      LEDpos p = new LEDpos();
      p.x2d = 0.50 + circle2DradiusInner * cos(v1);
      p.y2d = 0.50 + circle2DradiusInner * sin(v1);
      p.x3d = 0.00 + circle3DradiusInner * cos(v2);
      p.y3d = crownCenterHeight3D+ circle3DradiusInner * sin(v2);
      p.z3d = -circleThickness3D / 2;
      circle.pos[i+145] = p;
    }

    // pentacle
    LEDpos[] ppos = new LEDpos[10];
    for (int i=0;i<5;i++)
    {
      float a = radians(pentaFirstAngle  + i * 72);
      float x2d = 0.5 + cos(a) * penta2Dradius;
      float y2d = 0.5 + sin(a) * penta2Dradius;
      float x3d = cos(a) * penta3Dradius;
      float y3d = crownCenterHeight3D + sin(a) * penta3Dradius;
      float z3di = -pentaThickness3D / 2;
      float z3do = +pentaThickness3D / 2;
      LEDpos lpi = new LEDpos();
      LEDpos lpo = new LEDpos();
      lpi.x2d = x2d; lpo.x2d = x2d;
      lpi.y2d = y2d; lpo.y2d = y2d;
      lpi.x3d = x3d; lpo.x3d = x3d;
      lpi.y3d = y3d; lpo.y3d = y3d;
      lpi.z3d = z3di; lpo.z3d = z3do;
      ppos[i] = lpi;
      ppos[i+5] = lpo;
    }

    //   void lerpMap(LEDchain c, LEDpos p0, LEDpos p1, int index0, int index1)
   lerpMap(pentacle, ppos[0], ppos[3],  0, 15);
   lerpMap(pentacle, ppos[8], ppos[6], 17, 32);
   lerpMap(pentacle, ppos[1], ppos[4], 33, 49);
   lerpMap(pentacle, ppos[9], ppos[7], 50, 66);
   lerpMap(pentacle, ppos[2], ppos[0], 67, 82);
   lerpMap(pentacle, ppos[5], ppos[8], 84, 99);
   lerpMap(pentacle, ppos[3], ppos[1],100,115);
   lerpMap(pentacle, ppos[6], ppos[9],117,132);
   lerpMap(pentacle, ppos[4], ppos[2],134,149);
   lerpMap(pentacle, ppos[7], ppos[5],151,166);

}
  
  public void draw(PGraphics p)
  {
    draw3D(p);
  }
  
  int rot = 0;
  
  public void draw3D(PGraphics pg)
  {
    rot++;
    float xzs = pg.width ; 
    float ys = xzs;
    // float ys = pg.height * 0.5 ;  
    // float xzs = ys;
    float csxzs = 1/xzs;
    float csys = 1/ys;
    pg.beginDraw();
    pg.scale(xzs,ys,xzs);
    pg.translate(0.5,0.5,0.5); // tweak
    pg.pushMatrix();
    float yrot = radians(rot * rotationSpeed);
    pg.rotateY(yrot);
    pg.background(0xFF182838);
    pg.noStroke();
    for (int i=0;i<chains.size();i++)
    {
      LEDchain c = chains.get(i);
      int bufo = (c.bufReverse ? c.bufOffset + c.numLEDs - 1 : c.bufOffset);
      for (int j=0;j<c.numLEDs;j++)
      {
        LEDpos lp = c.pos[j];
        int rgb = srgbPixels[(c.bufReverse ? bufo-j : bufo+j)];
        pg.fill(rgb | 0xFF000000);
        pg.pushMatrix();
        pg.translate(lp.x3d, 1-lp.y3d, lp.z3d);
        pg.pushMatrix();
        pg.rotateY(-yrot);
        pg.scale(csxzs,csys,csxzs);
        pg.rect(-1,-1,2,2);
        pg.popMatrix();
        pg.popMatrix();
      }
    }
    pg.popMatrix();
    pg.fill(0xCC141C28);
    pg.triangle(-0.3,1.5,0,0.2,0.3,1.5);
    pg.endDraw();
  }
  

}