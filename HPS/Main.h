#ifndef _MAIN_H_
#define _MAIN_H_
#include "H2F.h"
#include "Keyboard.h"
#include "Buttons.h"
#include "Sequencer.h"

// Main class: manages top-level states.
// Author: Yibo Cao

class Main {
  H2F h2f;
  Buttons buttons;
  Keyboard keyboard;
  Sequencer sequencer;
  uint32_t timeBase;
  uint16_t keyInputs;
  uint8_t activeOctave, activeInst;
  void setOctave(uint8_t which);
  void setInst(uint8_t which);
  void onKeyInputChange(uint8_t key, bool on);
  void onKeyInputChange(uint8_t pitch, uint8_t inst, bool on);
public:
  Main();
  void loadDemoSong();
  void loadDrumLoop();
  void addDemoNote(uint32_t startTime, uint32_t duration,
    uint8_t pitch, uint8_t inst);
  void run();
  uint32_t getTimeBase() const { return timeBase; }
  void shiftOctave(bool positive);
  void shiftInst(bool positive);
  void scrollScreen(bool positive);
  uint8_t getOctave() const { return activeOctave; }
  uint8_t getInst() const { return activeInst; }
};

#endif
