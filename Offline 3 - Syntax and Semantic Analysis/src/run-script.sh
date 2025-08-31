#!/bin/bash

# Path to ANTLR4 jar
ANTLR_JAR="/home/vboxuser/antlr/antlr-4.13.2-complete.jar"

# Input test file is passed as $1
INPUT_FILE="$1"

# 1. Generate C++ parser and lexer files
java -Xmx500M -cp "$ANTLR_JAR" org.antlr.v4.Tool -Dlanguage=Cpp C8086Lexer.g4
java -Xmx500M -cp "$ANTLR_JAR" org.antlr.v4.Tool -Dlanguage=Cpp C8086Parser.g4

# 2. Compile all relevant source files
g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -c C8086Lexer.cpp C8086Parser.cpp Ctester.cpp hashfunction.cpp


# 3. Link with ANTLR4 runtime and create the executable
g++ -std=c++17 -w C8086Lexer.o C8086Parser.o Ctester.o hashfunction.o -L/usr/local/lib -lantlr4-runtime -o Ctester.out -pthread

# 4. Run with LD_LIBRARY_PATH pointing to runtime lib
LD_LIBRARY_PATH=/usr/local/lib ./Ctester.out "$INPUT_FILE"
