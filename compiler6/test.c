
#include <stdio.h>
#include <string.h>
#include "symtable.h"

Symbol** table;

int main(int argc, char** argv)
{
int i;
// create a new symbol table, do this in main()
table = newSymbolTable();
for (i=1; i<argc; i++) {
printf("argv[%d] == (%s)\n", i, argv[i]);
// add symbol to table, do this in variable declaration action
addSymbol(table, argv[i], 0, T_INT, 0, 0);
}
// iterate through table, do this to declare variables in assembly code
Symbol* symbol;
SymbolTableIter iterator;
iterator.index = -1;
while ((symbol=iterSymbolTable(table,0,&iterator)) != NULL) {
printf("%s:\t.word\t0\n",symbol->name);
}
return 0;
}
