# Grammar specification
This document contains Mi's grammar as it is used to parse source files.

```
program ::= [ { list } ] ;

list  ::= "(", { sexpr } | statement | expression | , ")" ;
sexpr ::= [ "'" ], atom | list ;
comment ::= ";", { ? all characters ? - ? newline ? }, ? newline ? ;

atom ::= identifier
       | number
       | string
       | boolean
       | null ;

null ::= "nil" ;
boolean ::= "true" | "false" ;
keyword ::= "lambda" | "define" | "use" | "loop" | "cond" | "if" | "case"
          | "try" | "catch" | "throw" | "not" | "and" | "or" | "eq" | "delete"
          | "typeof" | "void" | "new" | "instanceof" | "in" ;
reserved-keyword ::= boolean | null | keyword ;

digit  ::= "0" | ... | "9" ;
number ::= [ "-" ], { digit } | ( { digit }, ".", { digit } ) ;

string ::= '"', { ? all characters ? - '"' | '\"' }, '"' ;

letter ::= ( "a" | ... | "z" ) | ( "A" | ... | "Z" ) | "$" ;
identifier ::= ( letter, { letter | digit | "/" | "-" } ) - reserved-keyword ;

operator ::= "+" | "++" | "-" | "--" | "/" | "//" | "*" | "%" | "**" | "<" | "."
           | "=" | ">" | "<=" | ">=" | "<<" | ">>" | ">>>" | "~" | "^" | "|"
           | "&" | "not" | "and" | "or" | "eq" | "delete" | "typeof" | "void"
           | "new" | "instanceof" | "in" ;
expression ::= operator, { sexpr } ;

statement ::= lambda
            | define
            | use
            | if
            | defun
            | object
            | return
            | cond
            | loop ;

arg-list ::= "(", [ { identifier } ], ")" ;

lambda ::= "lambda", [ "*" ], [ identifier ], arg-list, { sexpr } ;
define ::= "define", [ "*" ], identifier, sexpr ;
use    ::= "use", ( [ "*" ], string, "'", identifier ) | string ;
if     ::= "if", sexpr, sexpr, [ sexpr ] ;
defun  ::= "defun", identifier, arg-list, { sexpr } ;
object ::= "object", { sexpr, sexpr } ;
return ::= "return", sexpr ;
cond   ::= "cond", { sexpr, sexpr } ;
loop   ::= "loop", "(", sexpr, [ sexpr, sexpr ],  ")", { sexpr } ;
```
