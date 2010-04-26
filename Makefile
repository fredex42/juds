SHELL = /bin/sh
VERSION = 0.93
PACKAGE = com.google.code.juds
PACKAGE_DIR = com/google/code/juds
TEST_SOCKET_FILE = JUDS_TEST_SOCKET_FILE
CC = gcc
JAVA_HOME = /System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home
JAVAC = /System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home/bin/javac
JAR = $(JAVA_HOME)/bin/jar
JAVAH = $(JAVA_HOME)/bin/javah

PREFIX = /usr
BASE_CFLAGS = -g -O2
JAVA_FLAGS = -g:none -deprecation -target 1.6

UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
    PLAT = darwin
    CFLAGS=$(BASE_CFLAGS) -dynamiclib -arch x86_64
    NATIVELIB=libunixdomainsocket.dylib
else
    PLAT = linux
    CFLAGS=$(BASE_CFLAGS) -shared
    NATIVELIB=libunixdomainsocket.so
endif
INCLUDEPATH = -I $(JAVA_HOME)/include -I $(JAVA_HOME)/include/$(PLAT)


all: jar nativelib

jar: juds-$(VERSION).jar

juds-$(VERSION).jar: $(PACKAGE_DIR)/UnixDomainSocket.class $(PACKAGE_DIR)/UnixDomainSocketClient.class $(PACKAGE_DIR)/UnixDomainSocketServer.class
	$(JAR) cf $@ $(PACKAGE_DIR)/*.class

nativelib: $(PACKAGE_DIR)/UnixDomainSocket.c $(PACKAGE_DIR)/UnixDomainSocket.h
	$(CC) $(CFLAGS) -fPIC $(INCLUDEPATH) -o $(NATIVELIB) $< 

$(PACKAGE_DIR)/UnixDomainSocket.h: $(PACKAGE).UnixDomainSocket
	$(JAVAH) -o $@ $<

$(PACKAGE).UnixDomainSocket: $(PACKAGE_DIR)/UnixDomainSocket.class

$(PACKAGE_DIR)/UnixDomainSocket.class: $(PACKAGE_DIR)/UnixDomainSocket.java
	$(JAVAC) $(JAVA_FLAGS) $?

$(PACKAGE_DIR)/UnixDomainSocketClient.class: $(PACKAGE_DIR)/UnixDomainSocketClient.java
	$(JAVAC) $(JAVA_FLAGS) $?

$(PACKAGE_DIR)/UnixDomainSocketServer.class: $(PACKAGE_DIR)/UnixDomainSocketServer.java
	$(JAVAC) $(JAVA_FLAGS) $?

install: nativelib
	cp $(NATIVELIB) $(PREFIX)/lib

uninstall:
	rm -f $(PREFIX)/lib/$(NATIVELIB)

test: $(PACKAGE_DIR)/test/TestUnixDomainSocket.class $(PACKAGE_DIR)/test/TestUnixDomainSocketServer.class
	python $(PACKAGE_DIR)/test/TestUnixDomainSocket.py $(TEST_SOCKET_FILE) &
	@sleep 2
	java -Djava.library.path=. $(PACKAGE).test.TestUnixDomainSocket $(TEST_SOCKET_FILE)
	rm -f $(TEST_SOCKET_FILE)
	java -Djava.library.path=. $(PACKAGE).test.TestUnixDomainSocketServer $(TEST_SOCKET_FILE)

$(PACKAGE_DIR)/test/TestUnixDomainSocket.class: $(PACKAGE_DIR)/test/TestUnixDomainSocket.java jar
	$(JAVAC) -cp juds-$(VERSION).jar $(JAVA_FLAGS) $<


$(PACKAGE_DIR)/test/TestUnixDomainSocketServer.class: $(PACKAGE_DIR)/test/TestUnixDomainSocketServer.java jar
	$(JAVAC) -cp juds-$(VERSION).jar $(JAVA_FLAGS) $<

clean:
	rm -f $(PACKAGE_DIR)/*.class $(PACKAGE_DIR)/test/*.class $(PACKAGE_DIR)/*.h *.so *.jar $(TEST_SOCKET_FILE)
