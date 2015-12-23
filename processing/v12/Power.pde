// This component attempts to predict 
// the aggregate power consumption of the whole installed system.

class PowerMeter
{
  long TlastIntegration = -1;
  boolean initialized = false;
  
  long majorCounter = 0; // whole watt hours        (3,600 joules(J) or 3,600,000 mJ)
  long minorCounter = 0; // whole milliwatt seconds (millijoules)
  
  public PowerMeter()
  {
    zero();
  }
  
  public void integrateLoad(double amperes, double volts)
  {
    integrateLoad(amperes * volts);
  }
  
  public void integrateLoad(double watts)
  {
    long Tnow = millis();
    if (!initialized)
    {
      initialized = true;
    }
    else
    {
      long quantMS = Tnow - TlastIntegration;
      long mJ = (long) (watts * quantMS);
      minorCounter += mJ;
      if (minorCounter >= 3600000)
      {
        // increment watt hours
        int ov = (int) (minorCounter / 3600000);
        majorCounter += ov;
        minorCounter -= 3600000 * ov;
      }
    }
    TlastIntegration = Tnow;
  }

  public void zero()
  {
    minorCounter = 0;
    majorCounter = 0;
    initialized = false;
  }

  public double getWH() // get watt hours
  {
     return (double) majorCounter + ((double) minorCounter / 3600000);
  }
  
  public double getAH(double volts) // get amp hours (at given voltage)
  {
    return getWH() / volts; 
  }

}