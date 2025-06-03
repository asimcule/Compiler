#
# Make file for simple scanner and parser example
#

# flags and defs for built-in compiler rules
CFLAGS = -I. -Wall -Wno-unused-function -g
CC = gcc

# default rule, build the parser into a 'ptest' executable
all: ptest

# yacc "-d" flag creates y.tab.h header
y.tab.c: parser.y
	yacc -d parser.y 

# lex rule includes y.tab.c to force yacc to run first
# lex "-d" flag turns on debugging output
lex.yy.c: scanner.l y.tab.c
	lex scanner.l

# Compile symtable.c into an object file
symtable.o: symtable.c symtable.h
	$(CC) $(CFLAGS) -c symtable.c

astree.o: astree.c astree.h
	$(CC) $(CFLAGS) -c astree.c

# ptest executable needs scanner and parser object files
ptest: lex.yy.o y.tab.o symtable.o astree.o
	gcc -o ptest y.tab.o lex.yy.o symtable.o astree.o

# ltest is a standalone lexer (scanner)
# build this by doing "make ltest"
# -ll for compiling lexer as standalone
ltest: scanner.l
	lex scanner.l
	gcc -DLEXONLY lex.yy.c -o ltest 

# Rule to feed input test file to the compiler
test: ptest
	@./ptest test.j > test.s

# clean the directory for a pure rebuild (do "make clean")
clean: 
	rm -f lex.yy.c a.out y.tab.c y.tab.h *.o *.s ptest ltest


memcheck: ptest
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./ptest test.j
