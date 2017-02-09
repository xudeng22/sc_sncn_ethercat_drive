CC = clang
LD = clang

WARNING = -Wall -Wextra
OPTIMIZIE = 2
CFLAGS = $(WARNING) -O$(OPTIMIZE) --std=c99 -g
LDFLAGS = $(WARNING)

TARGET = dctest
OBJECTS = main.o deviceconfig.o

%.o: %c
	$(CC) $(CFLAGS) -c -o $@ $^

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

.PHONY: clean

clean:
	@rm -f $(TARGET) $(OBJECTS)
