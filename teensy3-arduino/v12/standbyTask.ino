// stand-in simple test pattern as placeholder 

#define stb_numBlobs 40 // number of traveling dots

#define _hcc (_vidChains * 2) // half chain count
#define _hcl (_vidLength / 2) // half chain length

// #define _thunderOdds 1000

#define swA 17
#define swB 18

struct stb_Pixel
{
  unsigned int r     : 10;
  unsigned int g     : 10;
  unsigned int b     : 10;
};

struct stb_Blob
{
  unsigned int x     :  4;
  unsigned int size  :  6;
  unsigned int speed :  8;
  unsigned int y     : 16;
  unsigned int hue   : 16; 
  unsigned int hd    :  8; // hue speed
};

stb_Pixel stb_vb[_vidPixels];

stb_Blob stb_blobs[stb_numBlobs];

void stb_init()
{
  for (int i=0;i<stb_numBlobs;i++)
  {
    stb_generate(i);
  }
  #ifndef __switchOverride
  pinMode(swA, INPUT_PULLUP);
  pinMode(swB, INPUT_PULLUP);
  #endif
}

void stb_generate(int blobIndex)
{
  stb_Blob* blob = &stb_blobs[blobIndex];
  blob->x = random(_hcc); // select from among half-chains
  blob->y = 0;
  blob->size = 4 + random(7);   // random size
  blob->speed = 10 + random(40);  // speed
  // blob->hue = (fastEaseIn(random(4096))  * 382) >> 8; // favor lower end of hue scale with yumme reds and oranges
  blob->hue = random(65536);
  blob->hd = random(40);
  if (random(20) < 1) blob->hd = random(256);
}

int stb_iterate(int blobIndex)
{
  stb_Blob* blob = &stb_blobs[blobIndex];
  blob->y += blob->speed;
  blob->hue += blob->hd;
  if (blob->y > 19000)
  {
    stb_generate(blobIndex);
  }
  RGB32 tc;
  RGB32 blk;
  RGB32 tmp;
  rgb_set(&blk,0,0,0);
  int hue = blob->hue * 1530 / 65536;
  rgb_hsl(&tc, hue, 255, 255);
  int ty = (blob->y >> 7) - 40;
  int dy = blob->y & 0x7F;
  int xo = _hcl * blob->x;
  int m = 4096 / blob->size;
  int mo = dy * m >> 7;
  for (int i=0;i<blob->size;i++)
  {
    int y = ty - i;
    if ((y >= 0) && (y < _hcl))
    {
      int mx = (4095 - m * (i+1));
      mx = fastEaseIn(mx - mo < 0 ? 0 : mx - mo) >> 2;
      rgb_blend(&tmp, &blk, &tc, mx); // blend color
      stb_Pixel* p = &stb_vb[xo+y];
      int tr = p->r + tmp.r;
      int tg = p->g + tmp.g;
      int tb = p->b + tmp.b;
      p->r = (tr > 1023 ? 1023 : tr);
      p->g = (tg > 1023 ? 1023 : tg);
      p->b = (tb > 1023 ? 1023 : tb);
    }
  }
  for (int i=1;i<blob->size;i++)
  {
    int y = ty+i;
    if ((y >= 0) && (i > 0) && (y < _hcl))
    {
      int mx = (4095 - m * i);
      mx = fastEaseIn(mx + mo > 4095 ? 4095 : mx + mo) >> 2;
      rgb_blend(&tmp, &blk, &tc, mx); // blend color
      stb_Pixel* p = &stb_vb[xo+y];
      int tr = p->r + tmp.r;
      int tg = p->g + tmp.g;
      int tb = p->b + tmp.b;
      p->r = (tr > 1023 ? 1023 : tr);
      p->g = (tg > 1023 ? 1023 : tg);
      p->b = (tb > 1023 ? 1023 : tb);
    }
  }
  return 1;
}


void modeA()
{
  /*
  for (int i=0;i<_vidPixels;i++)
  {
    *(int*) &stb_vb[i] = 0;
  }
  */
  
  for (int i=0;i<_hcc;i++)
  {
    stb_Pixel p;
    *(int*) &p = 0;
    
    #ifdef _thunderOdds
    
    if (random(_thunderOdds) < 1)
    {
      RGB32 rgb;
      int hue = (fastEaseIn(random(4096))  * 382) >> 8; 
      rgb_hsl(&rgb, hue, 255, 255);
      p.r = rgb.r;
      p.g = rgb.g;
      p.b = rgb.b;
    }
    
    #endif
    
    int o = i * _hcl;
    int ip = *(int *) &p; 
    for (int j=0;j<_hcl;j++)
    {
      *(int*) &stb_vb[o++] = ip;
    }
  }
 
  for (int i=0;i<stb_numBlobs;i++)
  {
    stb_iterate(i);
  }
  
  /*
  for (int i=0;i<_vidPixels;i++)
  {
    stb_Pixel* p = &stb_vb[i];
    int r = p->r < 255 ? p->r : 255;
    int g = p->g < 255 ? p->g : 255;
    int b = p->b < 255 ? p->b : 255;
    octo.setPixel(i, (r << 16) | (g << 8) | b);
  }
  */
  
  for (int i=0;i<_hcc;i++)
  {
    if (i % 2)
    {
      int os = i * _hcl;
      int ot = os;
      for (int j=0;j<_hcl;j++)
      {
        stb_Pixel* p = &stb_vb[os++];
        int r = p->r < 255 ? p->r : 255;
        int g = p->g < 255 ? p->g : 255;
        int b = p->b < 255 ? p->b : 255;
        octo.setPixel(ot++, (r << 16) | (g << 8) | b);
      }
    }
    else
    {
      int os = i * _hcl;
      int ot = ((i+1) * _hcl) - 1;
      for (int j=0;j<_hcl;j++)
      {
        stb_Pixel* p = &stb_vb[os++];
        int r = p->r < 255 ? p->r : 255;
        int g = p->g < 255 ? p->g : 255;
        int b = p->b < 255 ? p->b : 255;
        octo.setPixel(ot--, (r << 16) | (g << 8) | b);
      }
    }
  }
}

void modeB()
{
  int rs = random(7) + 1; // choose random non-black color
  int rgb = ( (rs >> 2) & 0x01 ? 0xFF0000 : 0 ) | ((rs >> 1) & 0x01 ? 0x00FF00 : 0) | (rs & 0x01 ? 0x0000FF : 0); // solid
  for (int i=0;i<_vidPixels;i++)
  {
    octo.setPixel(i, rgb);
  }
}

void modeC()
{
  for (int i=0;i<_vidPixels;i++)
  {
    octo.setPixel(i, 0x000000);
  }
}

int stml = -1;

void standbyTask(int arg)
{
  int ms = 1;
  #ifndef __switchOverride
  ms = (!digitalRead(swA)) ? 1 : (!digitalRead(swB)) ? 2 : 0;
  #endif
  
  if (ms == 1)
  {
    // mode A
    modeA();
  }
  else if ((ms == 2) && (stml != ms))
  {
    // mode B
    modeB();
  }
  else if ((ms == 0) && (stml != ms))
  {
     // blackout
     modeC();
  }
  stml = ms;
  octo.show();
}

