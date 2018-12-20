#ifndef _NOTE_H_
#define _NOTE_H_
#include <cstdint>
#include <list>
#include <set>

// Note struct: stores the data of a note in the sequencer.
// Author: Yibo Cao

struct Note;
struct LessStartTime { bool operator()(const Note *x, const Note *y) const; };
struct LessEndTime { bool operator()(const Note *x, const Note *y) const; };

struct Note {
  using ItrList = std::list<Note>::iterator;
  using ItrView = std::list<Note*>::iterator;
  using ItrSetS = std::multiset<Note*, LessStartTime>::iterator;
  using ItrSetE = std::multiset<Note*, LessEndTime>::iterator;
  uint32_t startTime, duration;
  uint8_t pitch, inst;
  bool isInView;
  ItrList itrList;
  ItrSetS itrSetS;
  ItrSetE itrSetE;
  ItrView itrView;
  uint32_t endTime() const { return startTime + duration - 1; }
};

#endif
