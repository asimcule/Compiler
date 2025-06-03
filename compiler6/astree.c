//
// Abstract Syntax Tree Implementation
// - see "astree.h" for type definitions
// - the tree is made up of nodes of type ASTNode
// - the root node must be of type AST_PROGRAM
// - child nodes are linked by the "child[]" array, and
//   each type of node has its own children types
// - a special "child" node (the AST is a tree) uses
//   the "next" pointer to point to a "sibling"-type
//   node that is the next in a list (such as statements)
//
// Copyright (C) 2024 Jonathan Cook
//
#include <stdlib.h>
#include <stdio.h>
#include "astree.h"
#include "symtable.h"  // for DataType and VariableKind definition

// Symbol** symbolTable;
// Create a new AST node 
// - allocates space and initializes node type, zeros other stuff out
// - returns pointer to new node
ASTNode* newASTNode(ASTNodeType type)
{
   int i;
   ASTNode* node = (ASTNode*) malloc(sizeof(ASTNode));
   if (node == NULL)
      return NULL;
   node->type = type;
   node->valType = T_INT;
   node->varKind = V_GLOBAL;
   node->ival = 0;
   node->strval = 0;
   node->strNeedsFreed = 0;
   node->next = 0;
   for (i=0; i < ASTNUMCHILDREN; i++)
      node->child[i] = 0;
   return node;
}

// Generate an indentation string prefix
// - this is a helper function for use in printing the abstract
//   syntax tree with indentation used to indicate tree depth.
// - NOT thread safe! (uses a static char array to hold prefix)
#define INDENTAMT 3
static char* levelPrefix(int level)
{
   static char prefix[128]; // static so that it can be returned safely
   int i;
   for (i=0; i < level*INDENTAMT && i < 126; i++)
      prefix[i] = ' ';
   prefix[i] = '\0';
   return prefix;
}

// Free an entire ASTree, along with string data it has
// - a node must have strNeedsFreed to non-zero in order 
//   for its strval to be freed
void freeASTree(ASTNode* node)
{
   if (!node)
      return;
   freeASTree(node->child[0]);
   freeASTree(node->child[1]);
   freeASTree(node->child[2]);
   freeASTree(node->next);
   if (node->strNeedsFreed && node->strval){
      free(node->strval);
      node->strval = NULL;
   }
   free(node);
}

// Print the abstract syntax tree starting at the given node
// - this is a recursive function, your initial call should 
//   pass 0 in for the level parameter
// - comments in code indicate types of nodes and where they
//   are expected; this helps you understand what the AST looks like
// - "out" is the file to output to, can be "stdout" or other file handle
void printASTree(ASTNode* node, int level, FILE *out)
{
   char* instr;

   if (!node)
      return;
   fprintf(out,"%s",levelPrefix(level)); // note: no newline printed here!
   switch (node->type) {
    case AST_PROGRAM:
       fprintf(out,"Whole Program AST:\n");
       fprintf(out,"%s--globalvars--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out);  // child 0 is gobal var decls
       fprintf(out,"%s--functions--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is function defs
       fprintf(out,"%s--program--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out);  // child 2 is program
       break;
    case AST_VARDECL:
       fprintf(out,"Variable declaration (%s)",node->strval); // var name
       if (node->valType == T_INT)
          if (node->varKind != V_GLARRAY)
             fprintf(out," type int\n");
          else
             fprintf(out," type int array size %d\n",node->ival);
       else if (node->valType == T_LONG)
          fprintf(out," type long\n");
       else if (node->valType == T_STRING)
          fprintf(out," type string\n");
       else
          fprintf(out," type unknown (%d)\n", node->valType);
       break;
    case AST_FUNCTION:
       fprintf(out,"Function def (%s)\n",node->strval); // function name
       fprintf(out,"%s--params--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out); // child 0 is param list
       fprintf(out,"%s--locals--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out); // child 2 is local vars
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out); // child 1 is body (stmt list)
       break;
    case AST_SBLOCK:
       fprintf(out,"Statement block\n"); // we don't use this type
       printASTree(node->child[0],level+1,out);  // child 0 is statement list
       break;
    case AST_FUNCALL:
       fprintf(out,"Function call (%s)\n",node->strval); // func name
       printASTree(node->child[0],level+1,out);  // child 0 is argument list
       break;
    case AST_ARGUMENT:
       fprintf(out,"Funcall argument\n");
       printASTree(node->child[0],level+1,out);  // child 0 is argument expr
       break;
    case AST_ASSIGNMENT:
       fprintf(out,"Assignment to (%s) ", node->strval);
       if (node->varKind == V_GLARRAY) { //child[1]) {
          fprintf(out,"array var\n");
          fprintf(out,"%s--index--\n",levelPrefix(level+1));
          printASTree(node->child[1],level+1,out);
       } else  
          fprintf(out,"simple var\n");
       fprintf(out,"%s--right hand side--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out);  // child 1 is right hand side
       break;
    case AST_WHILE:
       fprintf(out,"While loop\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is loop body
       break;
    case AST_IFTHEN:
       fprintf(out,"If then\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--ifpart--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is if body
       fprintf(out,"%s--elsepart--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out);  // child 2 is else body
       break;
    case AST_EXPRESSION: // only for binary op expression
       fprintf(out,"Expression (op %d,%c)\n",node->ival,node->ival);
       printASTree(node->child[0],level+1,out);  // child 0 is left side
       printASTree(node->child[1],level+1,out);  // child 1 is right side
       break;
   case AST_RELEXPR: // only for relational op expression
         fprintf(out,"# Relational Expression (op %d,%c)\n",node->ival,node->ival);
         printASTree(node->child[0],level+1,out);  // child 0 is left side
         fprintf(out,"\taddi\tsp, sp, -4\n\tsw\tt0, 0(sp)\n");
         printASTree(node->child[1],level+1,out);  // child 1 is right side
         // decide which instruction to use based on operator
         switch (node->ival) {
         case '=': instr = "beq"; break;
         case '!': instr = "bne"; break;
         case '<': instr = "blt"; break;
         case '>': instr = "bgt"; break;
         default: instr = "unknown relop";
         }
         fprintf(out,"\tlw\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\t%s\tt1, t0, .LL%d\n",instr,level);
            break;
    case AST_VARREF:
       fprintf(out,"Variable ref (%s)",node->strval); // var name
       if (node->varKind == V_GLARRAY) { //child[0]) {
          fprintf(out," array ref\n");
          printASTree(node->child[0],level+1,out);
       } else 
          fprintf(out,"\n");
       break;
      case AST_CONSTANT: // for both int and string constants
       if (node->valType == T_INT)
          fprintf(out,"Int Constant = %d\n",node->ival);
       else if (node->valType == T_STRING)
          fprintf(out,"String Constant = (%s)\n",node->strval);
       else if (node->valType == T_RETURNVAL) // NEW
          fprintf(out,"Return Value\n");
       else 
          fprintf(out,"Unknown Constant\n");
       break;

       fprintf(out,"Unknown AST node!\n");
   }
   // IMPORTANT: walks down sibling list (for nodes that form lists, like
   // declarations, functions, parameters, arguments, and statements)
   printASTree(node->next,level,out);
}

//
// Below here is code for generating our output assembly code from
// an AST. You will probably want to move some things from the
// grammar file (.y file) over here, since you will no longer be 
// generating code in the grammar file. You may have some global 
// stuff that needs accessed from both, in which case declare it in
// one and then use "extern" to reference it in the other.

extern void outputDataSec(); // in main.c

// Used for labels inside code, for loops and conditionals
static int getUniqueLabelID()
{
   static int lid = 100; // you can start at 0, it really doesn't matter
   return lid++;
}

// Generate assembly code from AST
// - this function should look _alot_ like the print function;
//   indeed, the best way to start would be to copy over the 
//   code from printASTree() and change all the recursive calls
//   to this function; then, instead of printing info, we are 
//   going to print assembly code. Easy!
// - param node is the current node being processed
// - param hval is a helper value parameter that can be used to keep
//   track of value for you -- I use it only in two places, to keep
//   track of arguments and then to use the correct argument register
//   and to keep a label ID for conditional jumps on AST_RELEXPR 
//   nodes; otherwise this helper value can just be 0
// - param out is the output file handle. Use "fprintf(out,..." 
//   instead of printf(...); call it with "stdout" for terminal output
//   (see printASTree() code for how it uses the output file handle)
//
void genCodeFromASTree(ASTNode* node, int level, FILE *out)
{
   char* instr;
   int id1;
   int id2;
   // For you to write
   // 
   // As the comment above indicates, I use the second parameter to 
   // keep track of my argument register number as my recursive calls 
   // walk down the argument list; so in my function call case, my 
   // recursive call to child[0] (the arguments) uses a parameter
   // value of 0, then at the bottom of this function, the recursive
   // call on the next pointer looks like this:
   if (!node)
      return;
   fprintf(out,"%s",levelPrefix(level)); // note: no newline printed here!
   switch (node->type) {
    case AST_PROGRAM:
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is gobal var decls

       fprintf(out,"\t.text\n\nprogram:\n");
       genCodeFromASTree(node->child[2],level+1,out);  // child 2 is program
       fprintf(out,"\n\tli\ta0, 0\n\tli\ta7, 93\n\tecall");
       
       fprintf(out,"%s\n\n#--functions--\n",levelPrefix(level+1));
       genCodeFromASTree(node->child[1],level+1,out);  // child 1 is function defs


         fprintf(out, "\n\n#\n# some library functions\n#\n\n# Print a null-terminated string: arg: a0 == string address");
         fprintf(out, "\nprintStr:\n\tli\ta7, 4\n\tecall\n\tret\n");
         fprintf(out, "\n# Print a decimal integer: arg: a0 == value");
         fprintf(out, "\nprintInt:\n\tli\ta7, 1\n\tecall\n\tret\n\n");
         fprintf(out, "\n# Read in a decimal integer: return: a0 == value");
         fprintf(out, "\nreadInt:\n\tli	a7, 5\n\tecall\n\tret");

       break;
    case AST_VARDECL:
          if (node->varKind != V_GLARRAY && node->varKind == V_GLOBAL)
             fprintf(out,"%s:\t.word\t0\n",node->strval);
          else if(node->varKind == V_GLARRAY)
          {
             fprintf(out,"%s:\t.space\t%d\n",node->strval,node->ival);
          }
       else if (node->valType == T_INT && node->varKind != V_GLOBAL)
          fprintf(out,"\n\tsw\ta%d, %d(fp)", node->ival,4+4*(1+node->ival));
       else if (node->valType == T_LONG)
          fprintf(out," type long\n");
       else if (node->valType == T_STRING && node->varKind != V_GLOBAL)
          fprintf(out,"\n\tsw\ta%d, %d(fp)", node->ival,4+4*(1+node->ival));
       else
          fprintf(out," type unknown (%d)\n", node->valType);
       break;
    case AST_FUNCTION:
       fprintf(out,"\n%s:\n",node->strval); // function name
       
       fprintf(out,"\taddi\tsp, sp, -128\n\tsw\tra, 0(sp)\n\tsw\tfp, 4(sp)\n\tmv\tfp, sp\n");
       genCodeFromASTree(node->child[1],level+1,out);  // child 1 is params
       
       genCodeFromASTree(node->child[2],level+1,out);  // child 2 is vars
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is statements
       fprintf(out,"\n\tmv\tsp, fp\n\tlw\tra, 0(sp)\n\tlw\tfp, 4(fp)\n\taddi\tsp, sp, 128\n\tret");
       break;

    case AST_FUNCALL:
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is argument list
       fprintf(out,"\n\tjal\t%s",node->strval); // func name
       break;

    case AST_ARGUMENT:
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is argument expr
       fprintf(out,"\n\tmv\ta%d, t0", node->ival);
       break;

    case AST_ASSIGNMENT:
          genCodeFromASTree(node->child[0],level+1,out);
       if (node->varKind == V_GLARRAY) { 
          fprintf(out,"\n\taddi\tsp, sp, -4\n\tsw\tt0, 0(sp)\n"); // save RHS value onto stack
          genCodeFromASTree(node->child[1],0,out);  // generate code for index expression
         fprintf(out,"\n\tslli\tt0, t0, 2");
         fprintf(out,"\n\tla\tt1, %s",node->strval);
         fprintf(out,"\n\tadd\tt1, t1, t0");
         fprintf(out,"\n\tlw\tt0, 0(sp)");
         fprintf(out,"\n\taddi\tsp, sp, 4");
	      fprintf(out,"\n\tsw\tt0, 0(t1)");
         fprintf(out,"\n# array ref\n");

       } 
       else if (node->varKind == V_GLOBAL) {
            fprintf(out,"\n\tsw\tt0, %s, t1", node->strval);
          }
       else if (node->varKind == V_PARAM || node->varKind == V_LOCAL) {
            // fprintf(out,"\n\tsw\tt0, %s, t1", node->strval);
             fprintf(out,"\n\tsw\ta%d, %d(fp)", node->ival,4+4*(1+node->ival));
          }
       else 
            fprintf(out,"Unknown variable kind assignment\n");
       break;

    case AST_EXPRESSION: // only for binary op expression
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is left side
       fprintf(out,"\n\taddi\tsp, sp, -4\n\tsw\tt0, 0(sp)\t");
       genCodeFromASTree(node->child[1],level+1,out);  // child 1 is right side
       switch (node->ival) {
         case '-':
            fprintf(out,"\n\tlw\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\tsub\tt0, t1, t0");
         break;
         case '+':
            fprintf(out,"\n\tlw\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\tadd\tt0, t0, t1");
            break;
         default:
            fprintf(out,"Unknown Constant\n");
            break;
         }
       break;

   case AST_RELEXPR: // only for relational op expression
       fprintf(out,"\n#Relational Expression (op %d,%c)",node->ival,node->ival);
       genCodeFromASTree(node->child[0],level+1,out);  // child 0 is left side
       fprintf(out,"\n\taddi\tsp, sp, -4\n\tsw\tt0, 0(sp)\n");
       genCodeFromASTree(node->child[1],level+1,out);  // child 1 is right side
       switch (node->ival) {
        case '=': instr = "beq"; break;
        case '!': instr = "bne"; break;
        case '<': instr = "blt"; break;
        case '>': instr = "bgt"; break;
        default: instr = "unknown relop";
       }
       fprintf(out,"\n\tlw\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\t%s\tt1, t0, .LL%d\n",instr,level);
       break;

   case AST_WHILE:
         id1 = getUniqueLabelID();
         id2 = getUniqueLabelID();
         fprintf(out,"\n#While loop");
         fprintf(out,"\n\tb\t.LL%d\n",id2);  
         fprintf(out,"\n#--body--");
         fprintf(out,"\n.LL%d:\n",id1);  // body label
         genCodeFromASTree(node->child[1],level+1,out);  // child 1 is loop body

         fprintf(out,"\n.LL%d:\n",id2); //condition label
         genCodeFromASTree(node->child[0],id1,out);  // child 0 is condition expr
         break;

    case AST_IFTHEN:
       id1 = getUniqueLabelID();
       id2 = getUniqueLabelID();
       fprintf(out,"\n#If then");

       genCodeFromASTree(node->child[0],id1,out);  // child 0 is condition expr

       fprintf(out,"\n#--elsepart comes first--");
       genCodeFromASTree(node->child[2],level+1,out);  // child 2 is else body
       fprintf(out,"\n\tb\t.LL%d\n",id2);  // go to block after the if part
       fprintf(out,"\n#--end elsepart--");

       fprintf(out,"\n#--ifpart--");
       fprintf(out,"\n.LL%d:\n",id1); // if part label
       genCodeFromASTree(node->child[1],level+1,out);  // child 1 is if body
       fprintf(out,"\n#--end ifpart--");
       fprintf(out,"\n.LL%d:\n",id2); // rest of the code after if then else block
       break;

    case AST_VARREF:
      if (node->varKind == V_GLOBAL) {
         fprintf(out,"\n\tlw\tt0, %s",node->strval);
      }
      else if (node->varKind == V_PARAM || node->varKind == V_LOCAL) {
         fprintf(out,"\n\tlw\tt0, %d(fp)",4+4*(1+node->ival));

      }

       if (node->varKind == V_GLARRAY) { //child[0]) {
      //  # code for index expression above here
         genCodeFromASTree(node->child[0],level+1,out); // generate index expression code
         fprintf(out,"\n\tslli\tt0, t0, 2");
         fprintf(out,"\n\tla\tt1, %s",node->strval);
         fprintf(out,"\n\tlw\tt0, 0(t1)");
         fprintf(out,"\n# array ref\n");
         genCodeFromASTree(node->child[0],level+1,out);
       }
       break;
    case AST_CONSTANT: // for both int and string constants
       if (node->valType == T_INT)
          fprintf(out,"\n\tli\tt0, %d\n",node->ival);
       else if (node->valType == T_STRING)
          fprintf(out,"\n\tla\tt0, .SC%d", node->ival);
       else if (node->valType == T_RETURNVAL) // NEW
          fprintf(out,"\n\tmv\tt0, a0");
       else 
          fprintf(out,"Unknown Constant\n");
       break;
    default:
       fprintf(out,"Unknown AST node!\n");
   }
   genCodeFromASTree(node->next,level+1,out);
}

