#include "Keyboard.h"

Keyboard::Keyboard(H2F &h2f) :h2f(h2f), monitor(), sequencer() {
  for (uint8_t i = 0; i < 49; ++i)
    h2f.setKeyState(i, 0);
}

void Keyboard::setKey(uint8_t to[49], uint8_t pitch, uint8_t inst, bool on) {
  uint8_t &key = to[pitch];
  uint8_t mask = 1 << inst;
  if (on) key |= mask;
  else key &= ~mask;
  h2f.setKeyState(pitch, monitor[pitch] | sequencer[pitch]);
}

void Keyboard::setMonitor(uint8_t pitch, uint8_t inst, bool on) {
  setKey(monitor, pitch, inst, on);
}

void Keyboard::setSequencer(uint8_t pitch, uint8_t inst, bool on) {
  setKey(sequencer, pitch, inst, on);
}

void Keyboard::clearSequencer() {
  for (uint8_t i = 0; i < 49; ++i) {
    if (sequencer[i]) {
      sequencer[i] = 0;
      h2f.setKeyState(i, monitor[i]);
    }
  }
}
