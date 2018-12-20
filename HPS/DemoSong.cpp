#include "Main.h"

void Main::addDemoNote(uint32_t startTime, uint32_t duration,
    uint8_t pitch, uint8_t inst) {
  Note note;
  note.startTime = startTime;
  note.duration = duration;
  note.pitch = pitch;
  note.inst = inst;
  sequencer.addNote(note);
}

void Main::loadDrumLoop() {
  for (uint8_t i = 0; i < 16; ++i) {
    addDemoNote(i * 8 + 0, 1, 48, 0);
    addDemoNote(i * 8 + 2, 1, 48, 5);
    addDemoNote(i * 8 + 4, 1, 48, 4);
    addDemoNote(i * 8 + 6, 1, 48, 5);
  }
}

void Main::loadDemoSong() {
  // Intro square sweep
  auto introSqSweep = [&](uint32_t startTime, uint8_t p1, uint8_t p2) {
    addDemoNote(startTime + 0, 1, p1, 3);
    addDemoNote(startTime + 2, 1, p2, 3);
    addDemoNote(startTime + 3, 1, p1, 3);
  };
  introSqSweep(0,  24 + 9, 24 + 4);
  introSqSweep(4,  24 + 4, 24 + 0);
  introSqSweep(8,  24 + 0, 12 + 9);
  introSqSweep(12, 12 + 9, 12 + 4);
  introSqSweep(16, 12 + 4, 12 + 0);
  introSqSweep(20, 12 + 0, 0  + 9);
  introSqSweep(24, 0  + 9, 0  + 4);
  addDemoNote(28, 1, 4, 3);
  addDemoNote(30, 1, 7, 3);

  // Intro chord
  addDemoNote(0, 16 * 2, 12 + 9, 1);
  addDemoNote(0, 16 * 2, 12 + 4, 1);

  // Intro bass lead-in
  addDemoNote(16 + 8, 4, 24, 2);
  addDemoNote(16 + 9, 4, 0, 2);
  addDemoNote(16 * 2 - 2, 1, 12 + 2, 2);
  addDemoNote(16 * 2 - 1, 1, 12 + 4, 2);

  // Intro drum lead-in
  for (uint32_t i = 0; i < 8; ++i)
    addDemoNote(16 + i * 2, 1, 48, 5);
  for (uint32_t i = 0; i < 4; ++i) {
    addDemoNote(24 + i, 1, 48, 3 - i);
    addDemoNote(28 + i, 1, 48, 4);
    addDemoNote(28 + i, 1, 48, 0);
  }

  // Verse loop 1
  auto kickBass4 = [&](uint32_t startTime, uint8_t pitch, bool flag) {
    for (uint32_t i = 0; i < 4; ++i) {
      addDemoNote(startTime + i * 4 + 0, 1, 48, 5);
      addDemoNote(startTime + i * 4 + 2, 1, 48, 5);
      addDemoNote(startTime + i * 4 + 0, 1, 48, 0);
      addDemoNote(startTime + i * 4 + 2, 2, i < 3 || flag ? pitch : pitch - 2, 2);
    }
  };
  kickBass4(16 * 2, 12 + 5, true);
  kickBass4(16 * 3, 12 + 7, true);
  kickBass4(16 * 4, 12 + 9, true);
  kickBass4(16 * 5, 12 + 9, false);
  addDemoNote(16 * 6 - 3, 1, 48, 0);
  addDemoNote(16 * 6 - 2, 1, 48, 0);
  addDemoNote(16 * 6 - 2, 1, 48, 4);
  addDemoNote(16 * 6 - 1, 1, 48, 0);
  addDemoNote(16 * 6 - 1, 1, 48, 4);

  auto superArp4 = [&](uint32_t startTime, uint8_t pitch, bool flag) {
    for (uint32_t i = 0; i < (flag ? 2 : 1); ++i) {
      addDemoNote(startTime + i * 4 + 0, 1, pitch + 0, 1);
      addDemoNote(startTime + i * 4 + 1, 1, pitch + 7, 1);
      addDemoNote(startTime + i * 4 + 2, 1, pitch + 12, 1);
      addDemoNote(startTime + i * 4 + 3, 1, pitch + 19, 1);
    }
  };
  superArp4(16 * 2, 5, true);
  superArp4(16 * 3, 7, true);
  superArp4(16 * 4, 9, true);
  superArp4(16 * 5, 9, true);
  superArp4(16 * 5 + 12, 7, false);

  // Verse melody 1
  addDemoNote(32, 2, 12 + 9, 0);
  addDemoNote(34, 4, 24 + 0, 0);
  addDemoNote(38, 8, 24 + 5, 0);
  addDemoNote(38, 8, 24 + 9, 0);
  addDemoNote(46, 1, 24 + 7, 0);
  addDemoNote(47, 1, 24 + 9, 0);
  addDemoNote(48, 3, 24 + 11, 0);
  addDemoNote(51, 1, 24 + 9, 0);
  addDemoNote(52, 2, 24 + 7, 0);
  addDemoNote(54, 2, 24 + 4, 0);
  addDemoNote(56, 2, 24 + 2, 0);
  addDemoNote(58, 2, 24 + 4, 0);
  addDemoNote(60, 2, 24 + 7, 0);
  addDemoNote(62, 2, 24 + 2, 0);
  addDemoNote(64, 2, 24 + 4, 0);
  addDemoNote(66, 4, 24 + 9, 0);
  addDemoNote(70, 2, 24 + 9, 0);
  addDemoNote(72, 6, 24 + 0, 0);
  addDemoNote(78, 1, 24 + 0, 3);
  addDemoNote(79, 1, 24 + 2, 3);
  addDemoNote(80, 1, 24 + 4, 3);
  addDemoNote(82, 1, 24 + 9, 3);
  addDemoNote(86, 1, 24 + 9, 3);
  addDemoNote(88, 1, 24 + 0, 3);
  addDemoNote(92, 1, 12 + 11, 3);

  // Verse loop 2
  kickBass4(16 * 6, 12 + 5, true);
  kickBass4(16 * 7, 12 + 7, true);
  kickBass4(16 * 8, 12 + 0, true);

  superArp4(16 * 6, 5, true);
  superArp4(16 * 7, 7, true);
  addDemoNote(16 * 8 + 0 , 1, 12 + 0     , 1);
  addDemoNote(16 * 8 + 1 , 1, 12 + 4     , 1);
  addDemoNote(16 * 8 + 2 , 1, 12 + 7     , 1);
  addDemoNote(16 * 8 + 3 , 1, 12 + 12    , 1);
  addDemoNote(16 * 8 + 4 , 1, 12 + 4     , 1);
  addDemoNote(16 * 8 + 5 , 1, 12 + 7     , 1);
  addDemoNote(16 * 8 + 6 , 1, 12 + 12    , 1);
  addDemoNote(16 * 8 + 7 , 1, 12 + 12 + 4, 1);
  addDemoNote(16 * 8 + 8 , 1, 12 + 7     , 1);
  addDemoNote(16 * 8 + 9 , 1, 12 + 12    , 1);
  addDemoNote(16 * 8 + 10, 1, 12 + 12 + 4, 1);
  addDemoNote(16 * 8 + 11, 1, 12 + 12 + 7, 1);
  addDemoNote(16 * 8 + 12, 1, 12 + 24    , 1);
  addDemoNote(16 * 8 + 13, 1, 12 + 12 + 7, 1);
  addDemoNote(16 * 8 + 14, 1, 12 + 12 + 4, 1);
  addDemoNote(16 * 8 + 15, 1, 12 + 12 + 7, 1);

  auto verse2ending1 = [&](uint32_t startTime, uint32_t duration) {
    addDemoNote(startTime, duration, 12 + 4, 2);
    addDemoNote(startTime, duration, 12 + 11, 1);
    addDemoNote(startTime, duration, 12 + 12 + 4, 1);
    addDemoNote(startTime, duration, 12 + 12 + 8, 1);
  };
  verse2ending1(16 * 9 + 0, 1);
  verse2ending1(16 * 9 + 2, 1);
  verse2ending1(16 * 9 + 3, 1);
  verse2ending1(16 * 9 + 4, 1);
  verse2ending1(16 * 9 + 6, 10);
  addDemoNote(16 * 9 + 12, 4, 4, 2);
  addDemoNote(16 * 9 + 0, 1, 48, 3);
  addDemoNote(16 * 9 + 1, 1, 48, 2);
  addDemoNote(16 * 9 + 2, 1, 48, 1);
  addDemoNote(16 * 9 + 3, 1, 48, 0);
  addDemoNote(16 * 9 + 4, 1, 48, 0);
  addDemoNote(16 * 9 + 4, 1, 48, 4);
  addDemoNote(16 * 9 + 6, 1, 48, 0);
  addDemoNote(16 * 9 + 6, 1, 48, 4);
  addDemoNote(16 * 9 + 8, 1, 48, 5);
  addDemoNote(16 * 9 + 10, 1, 48, 5);
  for (uint32_t i = 1; i <= 4; ++i) {
    addDemoNote(16 * 10 - i, 1, 48, 0);
    if (i <= 2) addDemoNote(16 * 10 - i, 1, 48, 4);
  }

  // Verse melody 2
  addDemoNote(96,  2, 12 + 9, 0);
  addDemoNote(98,  4, 24 + 0, 0);
  addDemoNote(102, 8, 24 + 5, 0);
  addDemoNote(102, 8, 24 + 9, 0);
  addDemoNote(110, 1, 24 + 7, 0);
  addDemoNote(111, 1, 24 + 9, 0);
  addDemoNote(112, 3, 24 + 7, 0);
  addDemoNote(115, 1, 24 + 4, 0);
  addDemoNote(116, 2, 24 + 2, 0);
  addDemoNote(118, 2, 24 + 0, 0);
  addDemoNote(120, 2, 24 + 2, 0);
  addDemoNote(122, 2, 24 + 4, 0);
  addDemoNote(124, 2, 24 + 7, 0);
  addDemoNote(126, 2, 24 + 2, 0);
  addDemoNote(128, 2, 24 + 4, 0);
  addDemoNote(130, 4, 24 + 2, 0);
  addDemoNote(134, 10, 24 + 4, 0);

  // Verse loop 3
  kickBass4(16 * 10, 12 + 5, true);
  kickBass4(16 * 11, 12 + 7, true);
  kickBass4(16 * 12, 12 + 9, true);
  kickBass4(16 * 13, 12 + 2, true);
  kickBass4(16 * 14, 12 + 5, true);
  kickBass4(16 * 15, 12 + 7, true);

  superArp4(16 * 10, 5, true);
  superArp4(16 * 11, 7, true);
  superArp4(16 * 12, 9, true);
  superArp4(16 * 14, 5, true);
  superArp4(16 * 15, 7, true);
  superArp4(16 * 14 + 8, 12 + 5, true);
  superArp4(16 * 15 + 8, 12 + 7, true);
  addDemoNote(16 * 13 + 0,  1, 0  + 2, 1);
  addDemoNote(16 * 13 + 1,  1, 0  + 6, 1);
  addDemoNote(16 * 13 + 2,  1, 0  + 9, 1);
  addDemoNote(16 * 13 + 3,  1, 12 + 2, 1);
  addDemoNote(16 * 13 + 4,  1, 0  + 6, 1);
  addDemoNote(16 * 13 + 5,  1, 0  + 9, 1);
  addDemoNote(16 * 13 + 6,  1, 12  + 2, 1);
  addDemoNote(16 * 13 + 7,  1, 12  + 6, 1);
  addDemoNote(16 * 13 + 8,  1, 0  + 9, 1);
  addDemoNote(16 * 13 + 9,  1, 12 + 2, 1);
  addDemoNote(16 * 13 + 10, 1, 12 + 6, 1);
  addDemoNote(16 * 13 + 11, 1, 12 + 9, 1);
  addDemoNote(16 * 13 + 12, 1, 24 + 2, 1);
  addDemoNote(16 * 13 + 13, 1, 24 + 6, 1);
  addDemoNote(16 * 13 + 14, 1, 24 + 9, 1);
  addDemoNote(16 * 13 + 15, 1, 36 + 2, 1);

  // Verse melody 3
  auto verse3doubling = [&](uint32_t startTime, uint32_t duration, uint8_t pitch) {
    addDemoNote(startTime, duration, pitch, 0);
    addDemoNote(startTime, 1, pitch, 3);
  };
  verse3doubling(16 * 10 - 4, 2, 24 + 2);
  verse3doubling(16 * 10 - 2, 2, 24 + 0);
  verse3doubling(16 * 10 + 0, 2, 24 + 0);
  verse3doubling(16 * 10 + 2, 4, 12 + 9);
  verse3doubling(16 * 10 + 6, 8, 24 + 9);
  verse3doubling(16 * 10 + 14, 1, 24 + 7);
  verse3doubling(16 * 10 + 15, 1, 24 + 9);
  verse3doubling(16 * 10 + 16, 2, 24 + 7);
  verse3doubling(16 * 10 + 18, 1, 24 + 2);
  verse3doubling(16 * 10 + 19, 1, 24 + 4);
  verse3doubling(16 * 10 + 20, 2, 24 + 2);
  verse3doubling(16 * 10 + 22, 1, 24 + 0);
  verse3doubling(16 * 10 + 23, 1, 24 + 2);
  verse3doubling(16 * 10 + 24, 1, 24 + 4);
  verse3doubling(16 * 10 + 25, 1, 24 + 2);
  verse3doubling(16 * 10 + 26, 1, 24 + 0);
  verse3doubling(16 * 10 + 27, 1, 24 + 2);
  verse3doubling(16 * 10 + 28, 1, 24 + 2);
  verse3doubling(16 * 10 + 29, 1, 24 + 4);
  verse3doubling(16 * 10 + 30, 1, 24 + 7);
  verse3doubling(16 * 10 + 31, 1, 24 + 2);
  verse3doubling(16 * 10 + 32, 10, 24 + 4);
  verse3doubling(16 * 10 + 42, 2, 24 + 2);
  verse3doubling(16 * 10 + 44, 4, 24 + 0);
  verse3doubling(16 * 10 + 48, 10, 24 + 9);
  verse3doubling(16 * 10 + 58, 2, 24 + 11);
  verse3doubling(16 * 10 + 60, 4, 36 + 0);
  verse3doubling(16 * 10 + 64, 16, 24 + 9);
  verse3doubling(16 * 10 + 80, 4, 24 + 7);
  verse3doubling(16 * 10 + 84, 4, 24 + 4);
  verse3doubling(16 * 10 + 88, 4, 24 + 2);
  verse3doubling(16 * 10 + 92, 4, 24 + 7);
  verse3doubling(16 * 10 + 96, 6, 24 + 1);
  verse3doubling(16 * 10 + 102, 2, 24 + 9);
  verse3doubling(16 * 10 + 104, 24, 24 + 9);
  
  addDemoNote(16 * 16, 1, 48, 0);
  addDemoNote(16 * 16, 32, 9, 2);
  addDemoNote(16 * 16, 6, 12 + 9, 1);
  addDemoNote(16 * 16 + 6, 26, 12 + 4, 1);
}
