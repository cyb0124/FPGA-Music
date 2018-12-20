#include "Sequencer.h"
#include "Main.h"

Sequencer::Sequencer(H2F &h2f, Keyboard &keyboard, Main &main)
    :main(main), keyboard(keyboard), h2f(h2f), isPlaying(),
    tileStates(), tilePos(0), tileOffset(0) {
  h2f.setSubtileScroll(0);
  writeScrollRegs();
  for (uint16_t i = 0; i < 49 * 64; ++i)
    h2f.setTileState(i, 0);
}

bool Sequencer::shouldLockView() const {
  return isPlaying && isRecording;
}

void Sequencer::writeScrollRegs() {
  h2f.setGridScroll(tilePos + 8);
  h2f.setTileOffset(tileOffset);
}

void Sequencer::setTileState(uint8_t row, uint8_t pitch, uint8_t inst, uint8_t state) {
  uint16_t addr = static_cast<uint16_t>((row + tileOffset) & 63) * 49 + pitch;
  uint32_t mask = static_cast<uint32_t>(7) << (inst * 3);
  uint32_t &data = tileStates[addr];
  data &= ~mask;
  data |= static_cast<uint32_t>(state & 7) << (inst * 3);
  h2f.setTileState(addr, data);
}

void Sequencer::addToView(Note *note) {
  if (note->isInView) return;
  note->isInView = true;
  view.push_front(note);
  note->itrView = view.begin();
}

bool Sequencer::drawCompleteNote(Note *note, bool remove) {
  // How the note intersects the view.
  bool startPastBottom = tilePos < 8 || note->startTime >= tilePos - 8;
  bool startWithinTop = note->startTime <= tilePos + 55;
  bool endPastBottom = tilePos < 8 || note->endTime() >= tilePos - 8;
  bool endWithinTop = note->endTime() <= tilePos + 55;

  if (!startWithinTop || !endPastBottom) {
    // Out of screen.
    return false;
  } else {
    uint32_t rowStart = note->startTime - tilePos + 8;
    uint32_t rowEnd = note->endTime() - tilePos + 8;
    bool hasTopBorder = true, hasBottomBorder = true;
    if (startPastBottom) {
      if (endWithinTop) {
        // Note fully in screen.
      } else {
        // Note intersects top line.
        hasTopBorder = false;
        rowEnd = 55;
      }
    } else if (endWithinTop) {
      // Note intersects bottom line.
      hasBottomBorder = false;
      rowStart = 0;
    } else {
      // Screen fully in note.
      hasTopBorder = false;
      hasBottomBorder = false;
      rowStart = 0;
      rowEnd = 55;
    }
    for (uint32_t i = rowStart; i <= rowEnd; ++i) {
      uint8_t state;
      if (remove) {
        state = 0;
      } else {
        state = 1;
        if (hasBottomBorder && i == rowStart)
          state |= 2;
        if (hasTopBorder && i == rowEnd)
          state |= 4;
      }
      setTileState(i, note->pitch, note->inst, state);
    }
    return true;
  }
}

Note *Sequencer::addNote(const Note &params) {
  notes.push_front(params);
  Note *note = &notes.front();
  note->itrList = notes.begin();
  note->itrSetS = noteStarts.insert(note);
  note->itrSetE = noteEnds.insert(note);
  note->isInView = false;
  if (drawCompleteNote(note, false))
    addToView(note);
  return note;
}

Note::ItrView Sequencer::removeNote(Note *note) {
  Note::ItrView result;
  drawCompleteNote(note, true);
  if (note->isInView)
    result = view.erase(note->itrView);
  noteStarts.erase(note->itrSetS);
  noteEnds.erase(note->itrSetE);
  notes.erase(note->itrList);
  return result;
}

void Sequencer::writeRecordedNotes() {
  // Remove existing notes in the recording region.
  for (auto i = view.begin(); i != view.end();) {
    Note *note = *i;
    if (note->startTime <= tilePos + 1 && note->endTime() >= tilePos + 1
        && isNoteInRecordingRange(note)) {
      keyboard.setSequencer(note->pitch, note->inst, false);
      i = removeNote(note);
    } else {
      ++i;
    }
  }

  bool isDrum = main.getOctave() == 4;
  for (uint8_t i = 0; i < (isDrum ? 8 : 12); ++i) {
    Note *&note = recordingNotes[i];
    bool pressed = everPressed & (1 << i);
    bool released = everReleased & (1 << i);
    bool current = lastKeyStates & (1 << i);

    if (note) {
      if (released) {
        // Present note is released.
        note = nullptr;
        if (current)
          goto newNote;
      } else {
        // Present note is lengthened.
        Note params(*note);
        ++params.duration;
        removeNote(note);
        note = addNote(params);
      }
    } else if (pressed) newNote: {
      // New note is pressed.
      Note params;
      params.startTime = tilePos + 1;
      params.duration = 1;
      params.pitch = isDrum ? 48 : i + 12 * main.getOctave();
      params.inst = isDrum ? i : main.getInst();
      note = addNote(params);
      if (!current) {
        // The new note is immediately released.
        note = nullptr;
      }
    }
  }
}

void Sequencer::scroll(bool positive) {
  if (!positive && !tilePos)
    return;
  if (isPlaying) {
    if (positive) playNotesEnd();
    else keyboard.clearSequencer();
    if (isRecording) writeRecordedNotes();
  }

  // Remove notes that move out of view.
  for (auto i = view.begin(); i != view.end(); ) {
    Note *note = *i;
    bool shouldErase = false;
    if (!positive) {
      // Rise out of view.
      if (note->startTime <= tilePos + 55
          && note->endTime() >= tilePos + 55) {
        setTileState(63, note->pitch, note->inst, 0);
        shouldErase = note->startTime == tilePos + 55;
      }
    } else if (tilePos >= 8) {
      // Fall out of view.
      if (tilePos >= 8 && note->startTime <= tilePos - 8
          && note->endTime() >= tilePos - 8) {
        setTileState(0, note->pitch, note->inst, 0);
        shouldErase = note->endTime() == tilePos - 8;
      }
    }
    if (shouldErase) {
      i = view.erase(note->itrView);
      note->isInView = false;
    } else {
      ++i;
    }
  }

  // Scroll the screen.
  if (positive) {
    ++tilePos;
    ++tileOffset;
  } else {
    --tilePos;
    --tileOffset;
  }
  writeScrollRegs();

  // Add unfinished notes into view.
  for (Note *note : view) {
    if (positive) {
      // Fall into view.
      if (note->endTime() > tilePos + 55)
        setTileState(63, note->pitch, note->inst, 1);
      else if (note->endTime() == tilePos + 55)
        setTileState(63, note->pitch, note->inst, 5);
    } else if (tilePos >= 8) {
      // Rise into view.
      if (note->startTime < tilePos - 8)
        setTileState(0, note->pitch, note->inst, 1);
      else if (note->startTime == tilePos - 8)
        setTileState(0, note->pitch, note->inst, 3);
    }
  }

  // Add new notes into view.
  if (positive) {
    // Fall into view.
    Note target;
    target.startTime = tilePos + 55;
    auto range = noteStarts.equal_range(&target);
    for (auto i = range.first; i != range.second; ++i) {
      Note *note = *i;
      addToView(note);
      setTileState(63, note->pitch, note->inst,
        note->duration == 1 ? 7 : 3);
    }
  } else if (tilePos >= 8) {
    // Rise into view.
    Note target;
    target.startTime = tilePos - 8;
    target.duration = 1;
    auto range = noteEnds.equal_range(&target);
    for (auto i = range.first; i != range.second; ++i) {
      Note *note = *i;
      addToView(note);
      setTileState(0, note->pitch, note->inst,
        note->duration == 1 ? 7 : 5);
    }
  }

  if (positive && isPlaying)
    playNotesStart();
}

void Sequencer::update(bool play, bool record, uint16_t keyStates) {
  if (play) {
    // State updates for recording.
    if ((!isPlaying || !isRecording) && record) {
      everPressed = 0;
      everReleased = 0;
      for (Note *&i : recordingNotes)
        i = nullptr;
    }
    isRecording = record;
    lastKeyStates = keyStates;
    everPressed |= keyStates;
    everReleased |= ~keyStates;

    // Update scrolling and playback.
    if (!isPlaying) {
      lastBoundary = main.getTimeBase();
      playNotesStart();
    }
    uint32_t elapsed = main.getTimeBase() - lastBoundary;
    while (elapsed >= SAMPLES_PER_16TH) {
      elapsed -= SAMPLES_PER_16TH;
      lastBoundary += SAMPLES_PER_16TH;
      scroll(true);
      everPressed = 0;
      everReleased = 0;
    }
    h2f.setSubtileScroll(elapsed * 15 / SAMPLES_PER_16TH);
  } else if (isPlaying) {
    h2f.setSubtileScroll(0);
    keyboard.clearSequencer();
  }
  isPlaying = play;
}

void Sequencer::playNotesStart() {
  Note target;
  target.startTime = tilePos;
  auto range = noteStarts.equal_range(&target);
  for (auto i = range.first; i != range.second; ++i) {
    Note *note = *i;
    if (!isNoteInRecordingRange(note))
      keyboard.setSequencer(note->pitch, note->inst, true);
  }
}

void Sequencer::playNotesEnd() {
  Note target;
  target.startTime = tilePos;
  target.duration = 1;
  auto range = noteEnds.equal_range(&target);
  for (auto i = range.first; i != range.second; ++i) {
    Note *note = *i;
    keyboard.setSequencer(note->pitch, note->inst, false);
  }
}

bool Sequencer::isNoteInRecordingRange(const Note *note) {
  if (!isRecording) return false;
  uint8_t octave = note->pitch / 12;
  if (octave != main.getOctave()) return false;
  if (octave == 4) return true;
  return note->inst == main.getInst();
}
