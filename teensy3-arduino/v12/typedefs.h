typedef struct SchedTask SchedTask;

// -------------------------------------------------
// scheduler
// -------------------------------------------------

// method signature for scheduler task
// takes one integer index argument (optional task-defined use)
typedef void (*schTask) (int);

struct SchedTask
{
  unsigned int Tlast;
  unsigned int stepMicros;
  unsigned int argument : 8; // argument 
  unsigned int active : 1;   // active? 
  schTask taskFn;
  
  void clear()
  {
    this->active = false;
  }
  
  void init(schTask task, float hz, int argument)
  {
    this->taskFn = task;
    this->stepMicros = 1000000 / hz;
    this->Tlast = 0;
    this->argument = argument;
    this->active = true;
  }
  
  void check(unsigned int Tnow)
  {
    if (active)
    {
      if (abs(Tnow - this->Tlast) >= this->stepMicros)
      {
        this->Tlast = Tnow;
        this->taskFn(argument);
      }
    }
  }
  
};

// -------------------------------------------------
// libColor32
// -------------------------------------------------

struct RGB32
{
    unsigned int b: 8;           // blue:  0-255
    unsigned int g: 8;           // green: 0-255
    unsigned int r: 8;           // red:   0-255 
    unsigned int a: 8;           // alpha (?): 0-255
};

struct HSL32
{
    unsigned int h:12;           // hue:         0-1530 - 256 steps per sextant
    unsigned int s:8;            // saturation:  0-255 - 0 is greyscale, 255 is full saturation
    unsigned int l:8;            // luma:        0-255 - 0 is 100% black, 255 is full brightness
    unsigned int flags: 2;       // flags (2 spare bits)
};

// 64-bit structure containing both a RGB and HSL representation of a color
// Used in register-based color/hue manipulation 
// Think of it as a color provider
// Also has a RGB32 pointer that permits color refereral from auxiliary palette item or other color provider
struct COLOR
{
    RGB32* color;  // rgb pointer (internal or external)
    RGB32 rgb;     // rgb component (internal)
    HSL32 hsl;     // hsl representation (internal)
    
    void init()
    {
        hsl.h = 120;
        hsl.s = 127;
        hsl.l = 127;
        color = &rgb;
        rgb.r = 40;
        rgb.g = 40;
        rgb.b = 40;
    }
    
};

