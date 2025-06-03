
//
// Abstract Syntax Tree Interface
// - defines the ASTNode type, and the AST function interfaces
// - uses some DataType and VariableKind types from symtable.h
//
// Copyright (C) 2024 Jonathan Cook
//
#ifndef ASTREE_H
#define ASTREE_H

#include "symtable.h"  // for DataType and VariableKind definition

// AST node types: basically we have a different type for every 
// important program concept; these are ALMOST the same as our 
// grammar nonterminals, but since it is an ABSTRACT syntax tree
// we do NOT need exactly the same ones as our grammar nonterminals
// NOTE: we have some here that we are not using yet, like the while
// and ifthen and sblock (statement block) types. See bottom for more info.
typedef enum { 
   AST_PROGRAM, AST_VARDECL, AST_FUNCTION, AST_SBLOCK, AST_FUNCALL, 
   AST_ASSIGNMENT, AST_WHILE, AST_IFTHEN, AST_EXPRESSION, AST_VARREF, 
   AST_CONSTANT, AST_ARGUMENT, AST_RELEXPR
} ASTNodeType;

// max number of node children (3 will accomodate an ifthen node 
// that has its condition, ifblock, and elseblock as children)
// - each node type has different kinds or children, or none
#define ASTNUMCHILDREN 3

// AST Node definition; not all node types will use all the fields, each
//                      type just uses the fields it needs to
typedef struct astnode_s {
   ASTNodeType type; // type of this node
   DataType valType; // type for any data or variable referenced by this node
   VariableKind varKind; // if variable, kind (global, local, param, array)
   int ival;         // integer value if needed for this node type
   char* strval;     // string value if needed for this node type
   int strNeedsFreed; // tree freeing should also free the strval
   struct astnode_s* next;  // pointer to next node in sibling sequence
   struct astnode_s* child[ASTNUMCHILDREN]; // pointers to children, if any
} ASTNode;

// Function Prototypes -- see C file for detailed descriptions
ASTNode* newASTNode(ASTNodeType type);
void freeASTree(ASTNode* tree);
void printASTree(ASTNode* tree, int level, FILE *out);
void genCodeFromASTree(ASTNode* tree, int count, FILE *out);

#endif

//  Detailed description of each node type
//  - for anything that can be a sequence of things, the next field
//    points to the next in its sequence (vardecls, funcdecls, statements,
//    parameters, arguments)
//
// AST_PROGRAM -- root node for whole program
//                child[0] is global var decls
//                child[1] is function decls
//                child[2] is main program statements
// AST_VARDECL -- variable declaration; strval is var name; ival will be used
//                for local var offsets, array sizes, etc.
//                next is the next variable
// AST_FUNCTION - root node for function definition
//                child[0] is param decls
//                child[1] is function body
//                child[2] is local var decls
//                next is the next function def
// AST_SBLOCK  -- statement block -- not used for now
// AST_FUNCALL -- function call node; strval is function name;
//                child[0] is arguments
//                next is the next statement
// AST_ASSIGNMENT - assignment statement; strval is variable name
//                child[0] is right hand side expression
//                next is the next statement
// AST_WHILE   -- while loop statement
//                child[0] is condition expression
//                child[1] is loop body
//                next is the next statement
// AST_IFTHEN  -- if-then-else statement
//                child[0] is condition expression
//                child[1] is if block
//                child[2] is else block
//                next is the next statement
// AST_EXPRESSION - expression node; ival is the operator id number
//                child[0] is left subexpr
//                child[1] is right subexpr
// AST_VARREF  -- variable reference (read); strval is var name
//                ival and valtype will be used
// AST_CONSTANT - constant value; ival is int value for int constant,
//                strval is string for a string constant; valtype is set
// AST_ARGUMENT - function call argument
//                child[0] is expression of arg;
//                next is the next argument
// AST_RELEXPR  - a relational expr; child[0] and child[1] are expressions
//                (or varrefs or constants); ival is op id; strval is jump
//                label?
