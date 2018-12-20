#include "Buttons.h"
#include "Main.h"

Buttons::Buttons(Main &main)
  :main(main), wasPressed(),
  scrollCountN(), scrollCountP(),
  disableOctaveL(), disableOctaveR(),
  disableScrollN(), disableScrollP(),
  disableInstN(), disableInstP() {}

bool Buttons::hasDelayEnded(uint8_t which) {
  return main.getTimeBase() - lastUnpressed[which] >= BUTTONS_DELAY;
}

bool Buttons::checkScroll(uint8_t which, uint32_t &scrollCount) {
  uint32_t elapsed = main.getTimeBase() - lastUnpressed[which];
  uint32_t required = BUTTONS_DELAY;
  if (scrollCount)
    required += (scrollCount - 1) * SCROLL_INTERVAL + SCROLL_DELAY;
  bool result = elapsed >= required;
  if (result) ++scrollCount;
  return result;
}

void Buttons::update(uint8_t input) {
  for (uint8_t i = 0; i < 4; ++i) {
    bool pressed = input & 1 << i;
    if (!pressed)
      lastUnpressed[i] = main.getTimeBase();
    wasPressed[i] = pressed;
  }

  if (!wasPressed[3] && !wasPressed[2])
    disableInstN = false;
  else if (!disableInstN && wasPressed[3] && wasPressed[2]) {
    disableInstN = true;
    disableOctaveL = true;
    disableScrollN = true;
    main.shiftInst(false);
  }

  if (!wasPressed[1] && !wasPressed[0])
    disableInstP = false;
  else if (!disableInstP && wasPressed[1] && wasPressed[0]) {
    disableInstP = true;
    disableOctaveR = true;
    disableScrollP = true;
    main.shiftInst(true);
  }

  if (!wasPressed[3])
    disableOctaveL = false;
  else if (!disableOctaveL && hasDelayEnded(3)) {
    disableOctaveL = true;
    disableInstN = true;
    main.shiftOctave(false);
  }

  if (!wasPressed[2]) {
    disableScrollN = false;
    scrollCountN = 0;
  } else if (!disableScrollN && checkScroll(2, scrollCountN)) {
    disableInstN = true;
    main.scrollScreen(false);
  }

  if (!wasPressed[1]) {
    disableScrollP = false;
    scrollCountP = 0;
  } else if (!disableScrollP && checkScroll(1, scrollCountP)) {
    disableInstP = true;
    main.scrollScreen(true);
  }

  if (!wasPressed[0])
    disableOctaveR = false;
  else if (!disableOctaveR && hasDelayEnded(0)) {
    disableOctaveR = true;
    disableInstP = true;
    main.shiftOctave(true);
  }
}
