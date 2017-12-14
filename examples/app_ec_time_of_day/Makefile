CC = gcc
LD = gcc

CFLAGS = -O2 -std=c99 -Wall -Wextra -DDEBUG=0 -D_XOPEN_SOURCE
LDFLAGS = -Wall -Wextra

LIBS =

TARGET = app_ec_time_of_day
%.o: %.c
	$(CC) -c $(CFLAGS) $^ -o $@

all: $(TARGET)

$(TARGET): main.o
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

.PHONY: clean

clean:
	rm -f *.o $(TARGET)
