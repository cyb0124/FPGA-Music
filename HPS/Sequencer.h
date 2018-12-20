#ifndef _SEQUENCER_H_
#define _SEQUENCER_H_
#include "H2F.h"
#include "Note.h"
#include "Keyboard.h"

#define SAMPLES_PER_16TH 4800

// Sequencer: manages the list of notes.
// Author: Yibo Cao

class Sequencer {
  class Main &main;
  Keyboard &keyboard;
  H2F &h2f;
  bool isPlaying, isRecording;
  uint32_t lastBoundary;
  uint32_t tileStates[49 * 64];

  // Key states for recording.
  uint16_t everPressed, everReleased, lastKeyStates;

  // List of notes and two sorted indices for fast lookup.
  std::list<Note> notes;
  std::list<Note*> view;
  std::multiset<Note*, LessStartTime> noteStarts;
  std::multiset<Note*, LessEndTime> noteEnds;
  Note *recordingNotes[12];

  // Scrolling position.
  uint32_t tilePos;
  uint8_t tileOffset;

  void writeScrollRegs();
  void addToView(Note *note);
  void setTileState(uint8_t row, uint8_t pitch, uint8_t inst, uint8_t state);
  void playNotesStart();
  void playNotesEnd();
  bool isNoteInRecordingRange(const Note *note);
  void writeRecordedNotes();
  Note::ItrView removeNote(Note *note);
  // Draw a complete note on the screen.
  // Returns whether the note is visible at all.
  bool drawCompleteNote(Note *note, bool remove);
public:
  Sequencer(H2F &h2f, Keyboard &keyboard, Main &main);
  void update(bool play, bool record, uint16_t keyStates);
  void scroll(bool positive);
  Note *addNote(const Note &params);
  bool shouldLockView() const;
};

#endif
