# J-to-RISC-V Compiler

This is a work-in-progress compiler project for a custom language called **J**. The goal of the project is to compile high-level J programs into **RISC-V assembly**. The J language supports fundamental programming constructs such as:
Link to the J languge: https://www.cs.nmsu.edu/~jcook/posts/proglang-j/

- Loops 
- Conditional statements
- Arrays (Still working on it)
- Basic memory management (stack-based)

## 🔧 Project Focus

This compiler is primarily focused on the **scanning** and **parsing** phases of compilation. No optimizations have been implemented yet, and code generation is kept simple for clarity and educational value.

## 🧩 Components

- **Scanner**: Built using **Lex**, responsible for tokenizing the source code.
- **Parser**: Defined in **YAML**, it constructs the **Abstract Syntax Tree (AST)**.
- **Symbol Table**: Keeps track of variables, functions, types, and scopes throughout compilation.
- **AST**: Represents the hierarchical structure of the source code, aiding in semantic analysis and later stages.

## 🚀 Output

The compiler emits **RISC-V assembly**, which can be assembled and run using RISC-V emulators or simulators. 

## 📦 Features (Implemented)

- [x] Lexical analysis (scanner)
- [x] Parsing to AST
- [x] Symbol table management

Note: Actively working on it so it might still have some bugs 



