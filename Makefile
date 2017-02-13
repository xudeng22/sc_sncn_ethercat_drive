CC = gcc
LD = gcc
AR = ar

WARNING = -Wall -Wextra
OPTIMIZIE = 2
CFLAGS = $(WARNING) -O$(OPTIMIZE) --std=c99 -g -Iinclude
LDFLAGS = $(WARNING)
ARFLAGS = rcs

TARGETPATH = lib

TARGETBASE = readsdoconfig
TARGET = lib$(TARGETBASE).a
OBJECTS = src/deviceconfig.o

TEST = testreadconfig
TESTOBJ = src/main.o

%.o: %c
	$(CC) $(CFLAGS) -c -o $@ $^

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@test -d $(TARGETPATH) || mkdir $(TARGETPATH)
	$(AR) $(ARFLAGS) $(TARGETPATH)/lib$@.a $^

$(TEST): $(TESTOBJ) $(TARGET)
	$(LD) $(LDFLAGS) -o $@ $< -L$(TARGETPATH) -l$(TARGETBASE)

.PHONY: clean

clean:
	@rm -f $(TARGET) $(OBJECTS) $(TEST) $(TESTOBJ)
	@rm -rf $(TARGETPATH)
