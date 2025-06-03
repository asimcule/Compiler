%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"
int yyerror(char *s);
int yylex(void);
int debug=0;

Symbol** table;
ASTNode* astRoot;

char* savedStrings[100];
int lastStringIndex=0;
int argCount = 0;
int paramNum = 0;
// int currentScope = 0;
int addString(char* str)
{
   savedStrings[lastStringIndex] = strdup(str);
   return lastStringIndex++;
}
%}

/* token value data types */
%union {
   int ival; char* str; struct astnode_s * astnode;
}

%start wholeprogram
%type <astnode> program statements statement funcall function functions argument arguments expression globals parameters assignment vardecl paramdecl ifthenelse whileloop boolexpr localvars localdecl

%token <ival> KWPROGRAM KWCALL KWFUNCTION KWSTRING KWINT KWGLOBAL SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA NUMBER EQUALS KWRETURNVAL KWIF KWTHEN KWELSE KWWHILE KWDO RELOP ADDOP LBRACKET RBRACKET
%token <str> ID STRING

%%

wholeprogram: globals functions program 
   {
      astRoot = (ASTNode*) newASTNode(AST_PROGRAM);
      astRoot->child[0] = $1;
      astRoot->child[1] = $2;
      astRoot->child[2] = $3;
      astRoot->strval = NULL;
   }
program: KWPROGRAM LBRACE statements RBRACE
   {
      $$ = $3;
   }
functions:  /*empty*/
   {
      $$ = 0;
   }
   |function functions
   {
      $1->next=$2;
      $$ = $1;
   }
function: KWFUNCTION ID LPAREN parameters RPAREN LBRACE localvars statements RBRACE
   {
      $$ = (ASTNode*) newASTNode(AST_FUNCTION);
      $$->strval = $2;
      $$->strNeedsFreed = 1;
      $$->child[0] = $8; //stmnt
      $$->child[1] = $4; // params
      $$->child[2] = $7; // local vars
      delScopeLevel(table, 1); // important: remove param/local decls from symtable
      paramNum = 0;  // important: reset param/local counter
   }
whileloop: KWWHILE LPAREN boolexpr RPAREN KWDO LBRACE statements RBRACE
   {
      $$ = (ASTNode*) newASTNode(AST_WHILE);
      $$->child[0] = $3;
      $$->child[1] = $7;
      $$->child[2] = NULL;
      $$->strval=NULL;
   }
ifthenelse: KWIF LPAREN boolexpr RPAREN KWTHEN LBRACE statements RBRACE KWELSE LBRACE statements RBRACE
   {
      $$ = (ASTNode*) newASTNode(AST_IFTHEN);
      $$->child[0] = $3;
      $$->child[1] = $7;
      $$->child[2] = $11;
      $$->strval=NULL;
   }

statements: /*empty*/
   {
      $$ = 0;
   }
   | statement statements
   {
      $1->next=$2;
      $$ = $1;
   }
statement: funcall
   {
      $$ = $1;
   }
   | assignment
   {
      $$ = $1;
   }
   | ifthenelse
   {
      $$ = $1;
   }
   | whileloop
   {
      $$ = $1;
   }
funcall: KWCALL ID LPAREN arguments RPAREN SEMICOLON
   {
      argCount = 0;
      $$ = (ASTNode*) newASTNode(AST_FUNCALL);
      $$->strval = $2;
      $$->strNeedsFreed = 1;
      $$->child[0] = $4;
      $$->child[1] = NULL;
      $$->child[2] = NULL;
   }
arguments:  /*empty*/
   {
      $$ = 0;
   }
   | argument
   {
      $$ = $1;
   }
   | argument COMMA arguments
   {
      $1->next = $3;
      $$ = $1;
   }
argument: expression
   {
      if (debug) fprintf(stderr,"RULE:argument\n");
      $$ = (ASTNode*) newASTNode(AST_ARGUMENT);
      $$->child[0] = $1;
      $$->child[1] = NULL;
      $$->child[2] = NULL;
      $$->strval=NULL;
      $$->ival = argCount++;
   }
assignment: ID EQUALS expression SEMICOLON
   {
      Symbol* sym = findSymbol(table, $1);
      if(sym == NULL)
      // if(findSymbol(table, $1) == NULL)
      {
         fprintf(stderr, "Variable (%s) not declared. Exiting.\n", $1);
         exit(1);
      }
      else
      {
         $$ = (ASTNode*) newASTNode(AST_ASSIGNMENT);
         $$->strval = $1;
         $$->strNeedsFreed = 1;
         $$->child[0] = $3;
         $$->child[1] = NULL;
         $$->child[2] = NULL;
         $$->ival = sym->offset;
         $$->varKind = sym->varKind;
      }
   }
   | ID LBRACKET expression RBRACKET EQUALS expression SEMICOLON
   {
      if(findSymbol(table, $1) == NULL)
      {
         fprintf(stderr, "Variable (%s) not declared. Exiting.\n", $1);
         exit(1);
      }
      else
      {
         $$ = (ASTNode*) newASTNode(AST_ASSIGNMENT);
         $$->strval = $1;
         $$->strNeedsFreed = 1;
         $$->child[0] = $6;
         $$->child[1] = $3;
         $$->child[2] = NULL;
         $$->varKind = V_GLARRAY;

      }

   }
boolexpr: expression RELOP expression
   {
      $$ = (ASTNode*) newASTNode(AST_RELEXPR);
      $$->ival = $2;
      $$->strNeedsFreed = 0;
      $$->child[0] = $1;
      $$->child[1] = $3;
      $$->child[2] = NULL;
   }
expression: STRING
   {
      $$ = (ASTNode*) newASTNode(AST_CONSTANT);
      int sid = addString($1);
      $$->strval = $1;
      $$->ival = sid;
      $$->strNeedsFreed = 1;
      $$->valType = T_STRING;
      $$->child[0] = NULL;
      $$->child[1] = NULL;
      $$->child[2] = NULL;
   }
   | NUMBER
   {
      $$ = (ASTNode*) newASTNode(AST_CONSTANT);
      $$->ival = $1;
      $$->strNeedsFreed = 0;
      $$->valType = T_INT;
      $$->child[0] = NULL;
      $$->child[1] = NULL;
      $$->child[2] = NULL;
   }
   | ID
   {
      Symbol* sym = findSymbol(table, $1);
      if(sym == NULL)
      //if(findSymbol(table, $1) == NULL)
      {
         fprintf(stderr, "Variable (%s) not declared. Exiting.\n", $1);
         exit(1);
      }
      else
      {
         $$ = (ASTNode*) newASTNode(AST_VARREF);
         $$->strval = $1;
         $$->ival = sym->offset;
         $$->varKind = sym->varKind;
         $$->child[0] = NULL;
         $$->child[1] = NULL;
         $$->child[2] = NULL;
         $$->strNeedsFreed=1;
      }
   }
   | KWRETURNVAL
   {
      $$ = (ASTNode*) newASTNode(AST_CONSTANT);
      $$->valType = T_RETURNVAL;
   }
   | expression ADDOP expression
   {
      $$ = (ASTNode*) newASTNode(AST_EXPRESSION);
      $$->ival = $2;
      $$->strNeedsFreed = 0;
      $$->child[0] = $1;
      $$->child[1] = $3;
      $$->child[2] = NULL;
   }
   | ID LBRACKET expression RBRACKET
   {
      Symbol* sym = findSymbol(table, $1);
      if(sym == NULL)
      {
         fprintf(stderr, "Variable (%s) not declared. Exiting.\n", $1);
         exit(1);
      }
      else
      {
         $$ = (ASTNode*) newASTNode(AST_VARREF);
         $$->strval = $1;
         $$->child[0] = $3;
         $$->child[1] = NULL;
         $$->child[2] = NULL;
         $$->strNeedsFreed=1;
         $$->varKind = V_GLARRAY;
         $$->ival = sym->offset;
      }
   }

globals:  /*empty*/
   {
      if (debug) fprintf(stderr,"RULE:globals->empty\n");
      $$ = 0;
   }
| KWGLOBAL vardecl SEMICOLON globals
   {
      if (debug) fprintf(stderr,"RULE:globals->KWGLOBAL vardecl SEMICOLON globals\n");
      $2->next=$4;
      $$ = $2;
   }

vardecl:
KWINT ID
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 0, T_INT, 0, 0, V_GLOBAL) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else{
            $$ = (ASTNode*) newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->valType = T_INT;
            $$->varKind = V_GLOBAL;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
            $$->strNeedsFreed=1;

         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }
| KWSTRING ID
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 0, T_STRING, 0, 0, V_GLOBAL) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {
            $$ = (ASTNode*) newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->valType = T_STRING;
            $$->varKind = V_GLOBAL;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
            $$->strNeedsFreed=1;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }

   }
| KWINT ID LBRACKET NUMBER RBRACKET
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 0, T_INT, $4, 0, V_GLARRAY) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {
            $$ = newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->strNeedsFreed = 1;
            $$->valType = T_INT;
            $$->ival = $4;
            $$->varKind = V_GLARRAY;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }

parameters:
   {
      $$ = 0;
   }
| paramdecl
   {
      $$ = $1;
   }
| paramdecl COMMA parameters
   {
      $1->next = $3;
      $$ = $1;
   }

paramdecl:
KWINT ID
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 1, T_INT, 0, paramNum, V_PARAM) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {
            $$ = newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->strNeedsFreed = 1;
            $$->valType = T_INT;
            $$->ival = paramNum++;
            $$->varKind = V_PARAM;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }
| KWSTRING ID
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 1, T_STRING, 0, paramNum, V_PARAM) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {
            // addSymbol(table, $2, 1, T_STRING, 0, paramNum, V_PARAM);
            $$ = newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->strNeedsFreed = 1;
            $$->valType = T_STRING;
            $$->ival = paramNum++;
            $$->varKind = V_PARAM;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }

localvars:
   {
      $$ = 0;
   }
| localdecl SEMICOLON localvars
   {
      $1->next = $3;
      $$ = $1;
   }

localdecl:KWINT ID
   {

      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 1, T_INT, 0, paramNum, V_LOCAL) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {

            $$ = newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->strNeedsFreed = 1;
            $$->valType = T_INT;
            $$->ival = paramNum++;
            $$->varKind = V_LOCAL;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }
| KWSTRING ID
   {
      if(findSymbol(table, $2) == NULL)
      {
         if (addSymbol(table, $2, 1, T_STRING, 0, paramNum, V_LOCAL) < 0)
         {
            fprintf(stderr, "Error adding global variable (%s). Exiting.\n", $2);
            exit(1);
         }
         else
         {
            $$ = newASTNode(AST_VARDECL);
            $$->strval = $2;
            $$->strNeedsFreed = 1;
            $$->valType = T_STRING;
            $$->ival = paramNum++;
            $$->varKind = V_LOCAL;
            $$->child[0] = NULL;
            $$->child[1] = NULL;
            $$->child[2] = NULL;
         }
      }
      else
      {
         fprintf(stderr, "Variable (%s) already declared. Exiting.\n", $2);
         exit(1);
      }
   }


;
%%
/******* Functions *******/
extern FILE *yyin; // from lex
extern void yylex_destroy();

int main(int argc, char **argv)
{
   int stat = 1;
   int doAssembly = 1;
   int doTrace = 0;
   FILE *outputFile = NULL;
   char *inputFilename = NULL;
   char outputFilename[256];

   table = newSymbolTable();

   // Validating the command line arguments
   for (int i = 1; i < argc; i++) {
      if (strcmp(argv[i], "-t") == 0) {
         doTrace = 1;
      } else if (strcmp(argv[i], "-d") == 0) {
         doAssembly = 0;  //disable assembly generation
         printf("Please provide the j source code then hit ctrl+D to indicate EOF:\n");
      } else if (argv[i][0] == '-') {
         fprintf(stderr, "Error: Unknown argument '%s'\nExiting!", argv[i]);
         return 1;
      } else if (inputFilename == NULL) {
         inputFilename = argv[i];
      } else {
         fprintf(stderr, "Error: Too many input files. Only one .j file supported.\n\nExiting!");
         return 1;
      }
   }

   if (inputFilename == NULL) {
      // read from stdin
      yyin = stdin;
   } else {
      // Check for ".j" extension
      if (strlen(inputFilename) < 3 || strcmp(inputFilename + strlen(inputFilename) - 2, ".j") != 0) {
         fprintf(stderr, "Error: Input file must have a '.j' extension\n\nExiting!");
         return 1;
      }
      
      yyin = fopen(inputFilename, "r");
      if (!yyin) {
         fprintf(stderr, "Error: Unable to open input file '%s'\n\nExiting!", inputFilename);
         return 1;
      }

   if (doAssembly == 1) {
      // Out file (replace .j with .s)
      snprintf(outputFilename, sizeof(outputFilename), "%.*s.s", (int)(strlen(inputFilename) - 2), inputFilename);
      outputFile = fopen(outputFilename, "w");
      if (!outputFile) {
         fprintf(stderr, "Error: Unable to open output file '%s'\n\nExiting!", outputFilename);
         fclose(yyin);
         return 1;
      }
      }
   }

   // Toggling debugging flag
   if (doTrace) {
      fprintf(stderr, "Debugging enabled\n");
      debug = 1;
   }

   stat = yyparse();

   fclose(yyin);

   if (doAssembly == 1) {
      if (outputFile != NULL) {
         fprintf(outputFile, "\n\t.data\n");
         for (int i = 0; i < lastStringIndex; i++) {
            fprintf(outputFile, ".SC%d:   .string %s\n", i, savedStrings[i]);
            free(savedStrings[i]);
         }
         genCodeFromASTree(astRoot, 0, outputFile);
         fclose(outputFile);
      }
   }
   else{
   printASTree(astRoot, 0, stdout);
   }

   if (outputFile != NULL) {
      fclose(outputFile);
   }
   freeAllSymbols(table);
   free(table);
   freeASTree(astRoot);
   yylex_destroy();

   return stat;
}


extern int yylineno; // from lex

int yyerror(char *s)
{
   fprintf(stderr, "Error: line %d: %s\n",yylineno,s);
   return 0;
}

int yywrap()
{
   return(1);
}