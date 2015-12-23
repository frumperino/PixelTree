#define SM0 0x55
#define SM1 0xAA
#define SM2 0xFF

#define ser_fbytes (_vidPixels * 3)

unsigned int ser_ptr = 0;
unsigned int ser_sync = 0;
char ser_buf [ser_fbytes];

void serialTask(int arg)
{
  while (Serial.available())
  {
    switch(ser_sync)
    {
      case 0 : // not in sync : waiting for first sync mark
      {
        if (Serial.read() == SM0)
        {
          // first sync mark acquired. check for next mark.
          ser_sync = 1;
        }
      }
      break;
      case 1 : // still not in sync, but hunting for second sync mark
      {
        if (Serial.read() == SM1)
        {
          // good telltale. Now almost certainly in sync. Waiting for confirmation.
          ser_sync = 2;
        }
        else
        {
          // nope. back to square 1
          ser_sync = 0;
        }
      }
      break;
      case 2:
      {
        int c = Serial.readBytes(&ser_buf[0], ser_fbytes);
        ser_sync = 3;
      }
      break;
      case 3:
      {
        if (Serial.read() == SM0)
        {
          // sync confirmed
          ser_sync = 4;
        }
        else
        {
          ser_sync = 0; // start over
        }
      }
      break;
      case 4:
      {
        if (Serial.read() == SM1)
        {
          ser_sync = 5;
        }
        else
        {
          ser_sync = 0;
        }
      }
      case 5:
      {
        // now ready to read video frame
        int c = Serial.readBytes(&ser_buf[0], ser_fbytes);
        ser_displayFrame();
        ser_sync = 3;
      }
    }
  }
}

void ser_displayFrame()
{
  TlastFrame = millis(); // let's not forget the watchdog
  int j= 0;
  for (int i=0;i<_vidPixels;i++)
  {
     int r = ser_buf[j++];
     int g = ser_buf[j++];
     int b = ser_buf[j++];
     octo.setPixel(i, (r << 16) | (g << 8) | b);
  }
  if (operMode < 1) { goLive(); }
  octo.show();
}
