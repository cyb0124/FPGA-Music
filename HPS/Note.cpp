#include "Note.h"

bool LessStartTime::operator()(const Note *x, const Note *y) const {
  return x->startTime < y->startTime;
}

bool LessEndTime::operator()(const Note *x, const Note *y) const {
  return x->endTime() < y->endTime();
}
