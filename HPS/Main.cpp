#include "Main.h"
#include <exception>
#include <iostream>
#include <string>

Main::Main() :h2f(), buttons(*this), keyboard(h2f),
    sequencer(h2f, keyboard, *this),
    timeBase(0), keyInputs(0), activeOctave(1), activeInst(0) {
  // Initialize registers.
  h2f.setActiveOctave(activeOctave);
  h2f.setActiveInst(activeInst);
}

void Main::onKeyInputChange(uint8_t key, bool on) {
  if (activeOctave == 4) {
    if (key < 8) onKeyInputChange(48, key, on);
  } else {
    onKeyInputChange(12 * activeOctave + key, activeInst, on);
  }
}

void Main::onKeyInputChange(uint8_t pitch, uint8_t inst, bool on) {
  keyboard.setMonitor(pitch, inst, on);
}

void Main::setOctave(uint8_t which) {
  // Unregister pressed keys in old octave.
  for (uint8_t i = 0; i < 12; ++i)
    if (keyInputs & (1 << i))
      onKeyInputChange(i, false);

  // Change octave.
  h2f.setActiveOctave(activeOctave = which);

  // Register pressed keys in new octave.
  for (uint8_t i = 0; i < 12; ++i)
    if (keyInputs & (1 << i))
      onKeyInputChange(i, true);
}

void Main::setInst(uint8_t which) {
  if (activeOctave != 4) {
    // Unregister pressed keys for old instrument.
    for (uint8_t i = 0; i < 12; ++i)
      if (keyInputs & (1 << i))
        onKeyInputChange(i, false);
  }

  // Change instrument.
  h2f.setActiveInst(activeInst = which);

  if (activeOctave != 4) {
    // Register pressed keys for new instrument.
    for (uint8_t i = 0; i < 12; ++i)
      if (keyInputs & (1 << i))
        onKeyInputChange(i, true);
  }
}

void Main::shiftOctave(bool positive) {
  if (sequencer.shouldLockView()) return;
  if (positive)
    setOctave(activeOctave == 4 ? 0 : activeOctave + 1);
  else
    setOctave(activeOctave == 0 ? 4 : activeOctave - 1);
}

void Main::shiftInst(bool positive) {
  if (sequencer.shouldLockView()) return;
  if (positive)
    setInst(activeInst == 7 ? 0 : activeInst + 1);
  else
    setInst(activeInst == 0 ? 7 : activeInst - 1);
}

void Main::scrollScreen(bool positive) {
  if (sequencer.shouldLockView()) return;
  sequencer.scroll(positive);
}

void Main::run() {
  uint16_t prevSampleCount;
  for (bool firstCycle = true; ; firstCycle = false) {
    // Sample inputs.
    uint32_t rawInput = h2f.getInputs();

    // Update time base.
    uint16_t nowSampleCount = rawInput >> 18;
    if (!firstCycle)
      timeBase += (nowSampleCount - prevSampleCount) & 0x3FFF;
    prevSampleCount = nowSampleCount;

    // Process KEY[3:0] inputs.
    buttons.update(~rawInput);

    // Process keyboard input.
    uint16_t keyInputsNew = rawInput >> 6;
    for (uint8_t i = 0; i < 12; ++i)
      if ((keyInputs & (1 << i)) != (keyInputsNew & (1 << i)))
        onKeyInputChange(i, keyInputsNew & (1 << i));
    keyInputs = keyInputsNew;

    // Playback and recording.
    sequencer.update(rawInput & (1 << 4), rawInput & (1 << 5), keyInputs);
  }
}

int main(int argc, char *argv[]) {
  try {
    Main inst;
    if (argc == 2) {
      std::string arg(argv[1]);
      if (arg == "drum")
        inst.loadDrumLoop();
      else if (arg == "demo")
        inst.loadDemoSong();
    }
    inst.run();
  } catch (std::exception &x) {
    std::cout << "error: " << x.what() << std::endl;
  }
}
