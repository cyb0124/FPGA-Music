#ifndef _KEYBOARD_H_
#define _KEYBOARD_H_
#include "H2F.h"

// Keyboard: manages the keyboard display at the bottom of the screen.
// Author: Yibo Cao

class Keyboard {
  H2F &h2f;
  uint8_t monitor[49], sequencer[49];
  void setKey(uint8_t to[49], uint8_t pitch, uint8_t inst, bool on);
public:
  Keyboard(H2F &h2f);
  void setMonitor(uint8_t pitch, uint8_t inst, bool on);
  void setSequencer(uint8_t pitch, uint8_t inst, bool on);
  void clearSequencer();
};

#endif
