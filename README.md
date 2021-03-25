### FPGA Music Sequencer and Synthesizer

My personal project for creating a multitrack music sequencer including both hardware and software. See link below for a short demo. Sequencer note scheduling, state control, recording and playback are written in C++ running on the ARM processor. VGA display and the audio synthesizer are written in SystemVerilog running on the FPGA. Synthesizer contains 3 polyphonic instruments, 1 portamento instrument and 3 drums, all using subtractive synthesis with biquad and comb filters. Arithmetic is done using serialized (shared) fixed-point multiplier and divider modules, scheduled by several state machines. Demo music is composed during the testing of this project. Keyboard is designed in CAD and machined on a CNC.

[https://www.youtube.com/watch?v=CTeIdJ0tWsQ](https://www.youtube.com/watch?v=CTeIdJ0tWsQ)
