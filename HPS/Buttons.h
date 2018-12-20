#ifndef _BUTTONS_H_
#define _BUTTONS_H_
#include <cstdint>

#define BUTTONS_DELAY    4800
#define SCROLL_DELAY     12000
#define SCROLL_INTERVAL  1000

// Buttons: process the KEY[3:0] inputs.
// Author: Yibo Cao

class Buttons {
  class Main &main;
  bool wasPressed[4];
  uint32_t lastUnpressed[4];
  uint32_t scrollCountN, scrollCountP;
  bool disableOctaveL, disableOctaveR;
  bool disableScrollN, disableScrollP;
  bool disableInstN, disableInstP;
  bool hasDelayEnded(uint8_t which);
  bool checkScroll(uint8_t which, uint32_t &scrollCount);
public:
  Buttons(Main &main);
  void update(uint8_t input);
};

#endif
