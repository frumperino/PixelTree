// 32-bit color library 
// for use with Arduino Due, Teensy, and other 32-bit systems. 
// by Sonny Windstrup
// ------------------------------------------------------------------

// blend 8-bit component channel
// return a mix of input channels cin1 and cin2;
// ratio 0 : 100% channel cin1
// ratio 255 : 100% channel cin2
// ratio 127 : 49.8% channel cin1 + 50.2% channel cin2

byte ch_blend(byte cin1, byte cin2, byte ratio)
{
    // linear ratio is 0-255
    // c1 is 0-255
    // c2 is 0-255
    
    if ((cin1==cin2) || (ratio == 0))
    {
        return cin1;
    }
    else
    {
        unsigned int cd;
        if (cin2 > cin1)
        {
            cd = cin2-cin1;
            return (cin1 + ((ratio*cd) >> 8));
        }
        else
        {
            cd = cin1-cin2;
            return (cin2 + (((255-ratio)*cd) >> 8));
        }
    }
}

// blend RGB32
// return a mix of input channels cin1 and cin2;
// ratio 0 : 100% channel cin1    
// ratio 255 : 100% channel cin2
// ratio 127 : 49.8% channel cin1 + 50.2% channel cin2

void rgb_blend(RGB32 *cout, RGB32 *cin1, RGB32 *cin2, byte ratio)
{
    cout->r = ch_blend(cin1->r, cin2->r, ratio);
    cout->g = ch_blend(cin1->g, cin2->g, ratio);
    cout->b = ch_blend(cin1->b, cin2->b, ratio);
    cout->a = ch_blend(cin1->a, cin2->a, ratio);
}

void rgb_set(RGB32 *cout, int rgb32)
{
    *((int *) cout) = rgb32;
}

void rgb_set(RGB32 *cout, byte red, byte green, byte blue, byte alpha)
{
    cout->r = red;
    cout->g = green;
    cout->b = blue;
    cout->a = alpha;
}

void rgb_set(RGB32 *cout, byte red, byte green, byte blue)
{
    cout->r = red;
    cout->g = green;
    cout->b = blue;
    cout->a = 255;
}

void rgb_set(RGB32 *cout, RGB32 *cin)
{
    cout->r = cin->r;
    cout->g = cin->g;
    cout->b = cin->b;
    cout->a = cin->a;
}

// RGB from HSL
// write a RGB color based on H,S,L input
// hue is integer value between 0 and 1529 where 0/1529 is red, green is 510, blue is 1020.
// saturation is difference from greyscale output. (0 saturation is pure grey return).
// luminance is overall brightness (0 is black, 255 is full brightness).
void rgb_hsl(RGB32 *cout, unsigned int h, unsigned int s, unsigned int l)
{
    // integer version - faster than float version
    
    // hue can have one of 6 sextants:
    // sextant 0 :    0 ->  254    Red <-- [Yellow]
    // sextant 1 :  255 ->  509    Yellow <-- [Green]
    // sextant 2 :  510 ->  764    Green <-- [Cyan]
    // sextant 3 :  765 -> 1019    Cyan <-- [Blue]
    // sextant 4 : 1020 -> 1274    Blue <-- [Magenta]
    // sextant 5 : 1275 -> 1529    Magenta <-- [Red]
    
    unsigned int st = h / 255; // sextant
    unsigned int sv = h - st * 255; // phase
    
    unsigned int LE = l; // solid
    unsigned int LC = ((255-s) * l) >> 8; // neutral
    unsigned int LD = (sv * (l-LC)) >> 8; // variable
    cout->a = 0xFF;
    
    switch(st)
    {
        case 0 : // red to yellow
        {
            cout->r = LE;
            cout->g = LC+LD;
            cout->b = LC;
        }
        break;
        case 1 : // yellow to green
        {
            cout->r = LE-LD;
            cout->g = LE;
            cout->b = LC;
        }
        break;
        case 2 : // green to cyan
        {
            cout->r = LC;
            cout->g = LE;
            cout->b = LC+LD;
        }
        break;
        case 3: // cyan to blue
        {
            cout->r = LC;
            cout->g = LE-LD;
            cout->b = LE;
        }
        break;
        case 4: // blue to magenta
        {
            cout->r = LC+LD;
            cout->g = LC;
            cout->b = LE;
        }
        break;
        case 5: // magenta to red 
        {
            cout->r = LE;
            cout->g = LC;
            cout->b = LE-LD;
        }
        break;
        default: 
        {
            cout->r = 127;
            cout->g = 127;
            cout->b = 127;
        }
        break;
    }
}

void rgb_hsl(RGB32* cout, HSL32* hsl)
{
    rgb_hsl(cout, hsl->h, hsl->s, hsl->l);
}

// -------------------------------------------------
// Color manipulator section
// -------------------------------------------------

void col_setRGB(COLOR* c, unsigned int rgb32)
{
    *((unsigned int*) &c->rgb) = rgb32;
    c->color = &c->rgb;
}

void col_setRGB(COLOR* c, int r, int g, int b)
{
    rgb_set(&c->rgb, r,g,b);
    c->color = &c->rgb;
}

void col_setR(COLOR* c, int red)
{
    c->rgb.r = red;
    c->color = &c->rgb;
}

void col_setG(COLOR* c, int green)
{
    c->rgb.g = green;
    c->color = &c->rgb;
}

void col_setB(COLOR* c, int blue)
{
    c->rgb.b = blue;
    c->color = &c->rgb;
}

void col_setH(COLOR* c, int hue)
{
    c->hsl.h = hue;
    rgb_hsl(&c->rgb,&c->hsl);
    c->color = &c->rgb;
}

void col_setS(COLOR* c, int saturation)
{
    c->hsl.s = saturation;
    rgb_hsl(&c->rgb,&c->hsl);
    c->color = &c->rgb;
}

void col_setL(COLOR* c, int luminance)
{
    c->hsl.l = luminance;
    rgb_hsl(&c->rgb,&c->hsl);
    c->color = &c->rgb;
}


