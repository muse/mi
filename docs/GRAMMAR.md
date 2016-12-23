# Grammar specification
This document containts Mi's grammar as it is used to parse source files.

```
program ::= [ { list } ] ;

list  ::= "(", { sexpr } | statement | expresion | , ")" ;
sexpr ::= [ "'" ], atom | list ;
comment ::= ";", { ? all characters ? - ? newline ? }, ? newline ? ;

atom ::= identifier
       | number
       | string
       | boolean
       | null
       | operator ;

keyword ::= "lambda" | "define" | "use" | "loop" | "cond" | "if" | "case"
          | "try" | "catch" | "throw" | "not" | "and" | "or" | "eq" | "delete"
          | "typeof" | "void" | "new" | "instanceof" | "in" ;
reserved-keyword ::= boolean | null | keyword ;

digit  ::= "0" | ... | "9" ;
number ::= [ "-" ], { digit } | ( { digit }, ".", { digit } ) ;

string ::= '"', { ? all characters ? - '"' | '\"' }, '"' ;
boolean ::= "true" | "false" ;
null ::= "nil" ;

letter ::= ( "a" | ... | "z" ) | ( "A" | ... | "Z" ) ;
identifier ::= ( letter, { letter | digit | "/" | "-" | "$" } ) - reserved-keyword ;

operator ::= "+" | "++" | "-" | "--" | "/" | "//" | "*" | "%" | "**" | "<"
           | ">" | "<=" | ">=" | "<<" | ">>" | ">>>" | "~" | "^" | "|" | "&"
           | "not" | "and" | "or" | "eq" | "delete" | "typeof" | "void"
           | "new" | "instanceof" | "in" ;
expression ::= operator, { sexpr } ;

statement ::= use
            | define
            | if
            | defun
            | lambda ;

arg-list ::= "(", [ { identifier } ], ")" ;

use    ::= "use", ( [ "*" ], string, "'", identifier ) | string ;
define ::= "define", [ "*" ], identifier, sexpr ;
if     ::= "if", sexpr, sexpr, [ sexpr ] ;
defun  ::= "defun", identifier, arg-list, list ;
lambda ::= "lambda", [ "*", identifier ], arg-list, sexpr ;
```
