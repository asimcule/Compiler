/****
* Lex scanner for simple example
* - see the header comments in parser.y for more 
*   explanation of what this scanner does
****/

/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// The ifndef below allows this scanner definition to be
// used either with a yacc generated parser or all by
// itself (if LEXONLY is defined)
#ifndef LEXONLY
// definitions are auto-created by yacc so just include them
#include "y.tab.h"
extern int debug; // declared and set in parser.y
#else
// we must have explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define NUMBER 1
#define PLUS   2
#define STRING  3
#define LBRACE 4
#define RBRACE 5
#define LPAREN 6
#define KWPROGRAM 7
#define RPAREN 8
#define ID 9
#define KWCALL 10
#define SEMICOLON 11
#define COMMA 12
#define KWFUNCTION 13
#define EQUALS 14
#define KWINT 15
#define KWSTRING 16
#define KWGLOBAL 17
#define KWRETURNVAL 18
#define KWIF 19
#define KWTHEN 20
#define KWELSE 21
#define KWWHILE 22
#define KWDO 23
#define RELOP 24
#define ADDOP 25
#define LBRACKET 26
#define RBRACKET 27


int debug=1;
#endif
%}

/* This option is useful for printing out a syntax error
*  message and printing out the line # it occurred on
*/
%option yylineno

/****** Token Patterns ******/
%%
[ \t\n\r]+ { /* skipping white space */ }
[0-9]+   {
            if (debug) printf("lex: number(%s)\n", yytext);
            yylval.ival = strtol(yytext, NULL, 10);
            return(NUMBER);
         }
    
\+       {
            if (debug) printf("lex: (+)\n");
       	   yylval.ival = yytext[0];
            return(ADDOP);
         }
\-       {
            if (debug) printf("lex: (-)\n");
       	   yylval.ival = yytext[0];
            return(ADDOP);
         }
\>       {
            if (debug) printf("lex: >\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }
\<       {
            if (debug) printf("lex: <\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }
\=\=     {
            if (debug) printf("lex: ==\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }
\!\=     {
            if (debug) printf("lex: !=\n");
            yylval.ival = yytext[0];
            return(RELOP);
         }
\{       {
            if (debug) printf("lex: left curly braces\n");
            yylval.ival = yytext[0];
            return(LBRACE);
         }
\}       {
            if (debug) printf("lex: right curly braces\n");
            yylval.ival = yytext[0];
            return(RBRACE);
         }
\[       {
            if (debug) printf("lex: left brackets [\n");
            yylval.ival = yytext[0];
            return(LBRACKET);
         }
\]       {
            if (debug) printf("lex: right brackets ]\n");
            yylval.ival = yytext[0];
            return(RBRACKET);
         }
\(       {
            if (debug) printf("lex: left parenthesis\n");
            yylval.ival = yytext[0];
            return(LPAREN);
         }
\)       {
            if (debug) printf("lex: right parenthesis\n");
            yylval.ival = yytext[0];
            return(RPAREN);
         }
\;       {
            if (debug) printf("lex: semicolon\n");
            yylval.ival = yytext[0];
            return(SEMICOLON);
         }
\,       {
            if (debug) printf("lex: comma\n");
            yylval.ival = yytext[0];
            return(COMMA);
         }
\=       {
            if (debug) printf("lex: equals\n");
            yylval.ival = yytext[0];
            return(EQUALS);
         }
program  {
            if (debug) printf("lex: program\n");
            yylval.ival = yytext[0];
            return(KWPROGRAM);
         }
function {
            if (debug) printf("lex: function\n");
            yylval.ival = yytext[0];
            return(KWFUNCTION);
         }
call  	{
            if (debug) printf("lex: call\n");
            yylval.ival = yytext[0];
            return(KWCALL);
         }
int  	   {
            if (debug) printf("lex: int\n");
            yylval.ival = yytext[0];
            return(KWINT);
         }
if  	   {
            if (debug) printf("lex: if\n");
            yylval.ival = yytext[0];
            return(KWIF);
         }
then  	   {
            if (debug) printf("lex: then\n");
            yylval.ival = yytext[0];
            return(KWTHEN);
         }
else  	{
            if (debug) printf("lex: else\n");
            yylval.ival = yytext[0];
            return(KWELSE);
         }
while  	{
            if (debug) printf("lex: while\n");
            yylval.ival = yytext[0];
            return(KWWHILE);
         }
do     	{
            if (debug) printf("lex: do\n");
            yylval.ival = yytext[0];
            return(KWDO);
         }
returnvalue {
               if (debug) printf("lex: return\n");
               yylval.ival = yytext[0];
               return(KWRETURNVAL);
            }
string  	{
            if (debug) printf("lex: string\n");
            yylval.ival = yytext[0];
            return(KWSTRING);
         }
global  	{
            if (debug) printf("lex: global\n");
            yylval.ival = yytext[0];
            return(KWGLOBAL);
         }
[a-zA-Z_][0-9a-zA-Z_]*  {
                           if (debug) printf("lex: id (%s)\n", yytext);
                           // creating a copy of the string is important, but
                           // in this small program we are leaking this memory,
                           // we don't clean it up; needs fixed in bigger program!
                           yylval.str = strdup(yytext);
                           return(ID);
         		         }

\"[^\"]+\" {
            if (debug) printf("lex: string\n");
            yylval.str = strdup(yytext);
            return(STRING);
           }
         


%%
/****** Functions (not used when used with parser) *******/

//
// Code in the ifdef block below is only for compiling the
// scanner all by itself, for testing purposes. The 
// Makefile shows how to compile it under the "ltest" rule
// (do "make ltest" to build it)
//
#ifdef LEXONLY

// A main for standalone testing (uses just stdin as input)
int main(int argc, char **argv) 
{
   do {
      yylex();
   } while (1);
   // while (!feof(stdin)); doesn't work if redirecting a file
   // in because the file is read in and buffered, and eof is
   // true too early, causing lex to stop; rather, use while(1)
   // and then do a hard exit in yywrap(); ugly, but works!
   return 0;
}

int yywrap()
{
   exit(0); // hard exit!
   //return(1);
}

#endif // LEXONLY


