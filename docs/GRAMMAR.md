# Grammar specification
This document containts Mi's grammar as it is used to parse source files.

```
program ::= [ { list } ] ;

list  ::= "(", { sexpr } | statement, ")" ;
sexpr ::= ( [ "'" ], atom | list ) | ;

digit  ::= "0" | ... | "9" ;
letter ::= ( "a" | ... | "z" ) | ( "A" | ... | "Z" ) ;

identifier ::= letter, { letter | digit | "/" | "-" | "$" } ;

operator   ::= "+" | "++" | "-" | "--" | "/" | "//" | "*" | "%" | "**" | "<"
             | ">" | "<=" | ">=" | "<<" | ">>" | ">>>" | "~" | "^" | "|" | "&"
             | "not" | "and" | "or" | "eq" | "delete" | "typeof" | "void"
             | "new" | "instanceof" | "in" | "from" ;
string     ::= '"', { ? all characters ? - '"' | '\"' }, '"' ;
symbol     ::= ":", { letter | "_" | "-" | "+" | "*" | "/" | "%" | "^" | "@"
                    | "!" | "&" | "|" } ;
number ::= [ "-" ], { digit } | ( { digit }, ".", { digit } ) ;
scientific-number ::= { number }, "e", [ "-" ], { digit } ;

atom ::= identifier
       | number
       | scientific-number
       | string
       | symbol
       | operator ;

statement ::= use
            | define
            | defun
            | lambda ;

arg-list ::= "(", [ { identifier } ] , ")" ;

use    ::= "use", [ "*" ], list | string ;
define ::= "define", [ "*" ], identifier, sexpr ;
defun  ::= "defun", identifier, arg-list, list ;
lambda ::= "lambda", [ identifier ], arg-list, sexpr ;
```
