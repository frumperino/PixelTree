unsigned int sines[512]; 

void fastSinSetup()
{
    for (int i=0;i<1024;i++)
    {
        float deg = (float) i * 90 / 1024;
        unsigned int value = 2048 * sin(radians(deg));
        if (i < 512)
        {
            // sector 0
            sines[i & 0x1FF] = value;
        }
        else
        {
            // sector 1
            sines[i & 0x1FF] |= (value << 16);
        }
    }
}

int fastSin(int angle)
{
    // input angle is 12-bit positive integer (0 - 4095)
    // divided into 8 sectors each 45 degrees (quarter pi theta)

    // output is 12-bit positive integer 
    // with mid-interval (2048) representing 0 value;
   //  0 represents -1 and 4097 represents +1.
   
    int sector = (angle >> 9) & 0x07;
    int index = angle & 0x1FF;
    switch(sector)
    {
        case 0 : return 2048 + (sines[index] & 0xFFF);
        case 1 : return 2048 + ((sines[index] >> 16) & 0xFFF);
        case 2 : return 2048 + ((sines[511-index] >> 16) & 0xFFF);
        case 3 : return 2048 + (sines[511-index] & 0xFFF);
        case 4 : return 2047 - (sines[index] & 0xFFF);
        case 5 : return 2047 - ((sines[index] >> 16) &0xFFF);
        case 6 : return 2047 - ((sines[511-index] >> 16) & 0xFFF);
        case 7 : return 2047 - (sines[511-index] & 0xFFF);
        default: return 0;
    }
}

int fastCos(int angle)
{
  return fastSin(angle + 1024); // turn phase 90 degrees
}

int fastEaseLinear(int phase)
{
  // kind of nonsensical, but implemented for compatibility with motorslider library:
  // simply provides a linear interpolation between 0 .. 1023 in response to a phase
  // progression from 0 - 4095. 
  return ((phase >> 2) & 0x3FF);
}

int fastEaseIn(int phase)
{
  // uses fastSin to produce an "ease in" 10-bit waveform response to a phase progression from 0 - 4095. 
  // this solution uses sine phase 270 through 360 degrees for the function response.
  return ((fastSin(3072 + (phase >> 2))) >> 1) & 0x3FF;
}

int fastEaseOut(int phase)
{
  // uses fastSin to produce an "ease out" 10-bit waveform response to a phase progression from 0 - 4095. 
  // this solution uses sine phase 0 through 90 degrees for the function response.
  return ((fastSin(phase >> 2) - 2048) >> 1) & 0x3FF;
}

int fastEaseInOut(int phase)
{
  // uses fastSin to produce an "ease in and out" 10-bit waveform response to a phase progression from 0 - 4095. 
  // this solution uses sine phase 270 through 90 degrees for the function response.
  return ((fastSin(3072 + (phase >> 1))) >> 2) & 0x3FF; 
}


