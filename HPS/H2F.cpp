#include <stdexcept>
#include <unistd.h>
#include <sys/fcntl.h>
#include <sys/mman.h>
#include "H2F.h"

#define H2F_LW_BASE 0xFF200000
#define H2F_LW_SPAN 0x00000004

H2F::H2F() :mem(open("/dev/mem", O_RDWR | O_SYNC | O_CLOEXEC)) {
  if (mem.fd < 0)
    throw std::runtime_error("failed to open /dev/mem");
  void *base = mmap(nullptr, H2F_LW_SPAN, PROT_READ | PROT_WRITE,
    MAP_SHARED, mem.fd, H2F_LW_BASE);
  if (base == MAP_FAILED)
    throw std::runtime_error("failed to mmap");
  this->base = static_cast<volatile uint32_t*>(base);
}

H2F::~H2F() {
  munmap(const_cast<uint32_t*>(base), H2F_LW_SPAN);
}

void H2F::setBits(uint32_t offset, uint8_t bStart, uint8_t bLen, uint32_t value) {
  uint32_t mask = ((uint32_t(1) << bLen) - 1) << bStart;
  base[offset] = (base[offset] & ~mask) | (value << bStart & mask);
}

void H2F::setSubtileScroll(uint8_t value) { setBits(0, 0,  4, value); }
void H2F::setGridScroll(uint8_t value)    { setBits(0, 4,  4, value); }
void H2F::setActiveOctave(uint8_t value)  { setBits(0, 8,  3, value); }
void H2F::setActiveInst(uint8_t value)    { setBits(0, 11, 3, value); }
void H2F::setTileOffset(uint8_t value)    { setBits(4, 0,  6, value); }

void H2F::setKeyState(uint8_t key, uint8_t value) {
  setBits(0, 14, 14, static_cast<uint16_t>(value) << 6 | key);
}

void H2F::setTileState(uint16_t addr, uint32_t data) {
  setBits(4, 6, 12, addr);
  setBits(8, 0, 24, data);
}

uint32_t H2F::getInputs() {
  return base[12];
}
