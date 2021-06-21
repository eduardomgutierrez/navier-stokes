CU=nvcc
CUFLAGS=-O2 -Xcompiler=-Wall -ccbin clang-6.0 -arch=sm_75
LDFLAGS=

TARGETS=demo headless
SOURCES=$(shell echo *.cu) 
COMMON_OBJECTS=solver.o

all: $(TARGETS)

demo: demo.o $(COMMON_OBJECTS)
	$(CU) $(CUFLAGS) $^ -o $@ $(LDFLAGS) -lGL -lGLU -lglut

headless: headless.o $(COMMON_OBJECTS)
	$(CU) $(CUFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cu
	$(CU) $(CUFLAGS) -o $@ -c $<

clean:
	rm -f $(TARGETS) *.o .depend *~

-include .depend

.PHONY: clean all
