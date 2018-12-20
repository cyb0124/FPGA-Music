#ifndef _H2F_H_
#define _H2F_H_
#include <cstdint>
#include "FDGuard.h"

// This class handles HPS to FPGA communication.
// Author: Yibo Cao

class H2F {
  FDGuard mem;
  volatile uint32_t *base;
  void setBits(uint32_t offset, uint8_t bStart, uint8_t bLen, uint32_t value);
public:
  H2F();
  ~H2F();
  void setSubtileScroll(uint8_t value);
  void setGridScroll(uint8_t value);
  void setActiveOctave(uint8_t value);
  void setActiveInst(uint8_t value);
  void setKeyState(uint8_t key, uint8_t value);
  void setTileOffset(uint8_t value);
  void setTileState(uint16_t addr, uint32_t data);
  uint32_t getInputs();
};

#endif
