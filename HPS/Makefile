CXXFLAGS=-static -std=c++11 -Wall -Wextra -O2
CXXSOURCES=$(wildcard *.cpp)

all: run
.PHONY: all

%.o: %.cpp $(wildcard *.h)
	arm-linux-gnueabihf-g++ -c $(CXXFLAGS) -o $@ $<

run: $(CXXSOURCES:.cpp=.o)
	arm-linux-gnueabihf-g++ -o $@ $(CXXFLAGS) $^

clean:
	rm -rf *.o run
.PHONY: clean

.SUFFIXES:
