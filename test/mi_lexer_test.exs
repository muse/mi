defmodule MiLexerTest do
  alias Mi.Lexer
  alias Mi.Token
  use   ExUnit.Case

  describe "&Lexer.lex/1" do
    test "Keywords are recognized" do
      result = Lexer.lex("lambda let set or and not use loop cond case try catch throw true false nil")
      assert [%Token{type: :lambda, value: 'lambda'},
              %Token{type: :let, value: 'let'},
              %Token{type: :set, value: 'set'},
              %Token{type: :or, value: 'or'},
              %Token{type: :and, value: 'and'},
              %Token{type: :not, value: 'not'},
              %Token{type: :use, value: 'use'},
              %Token{type: :loop, value: 'loop'},
              %Token{type: :cond, value: 'cond'},
              %Token{type: :case, value: 'case'},
              %Token{type: :try, value: 'try'},
              %Token{type: :catch, value: 'catch'},
              %Token{type: :throw, value: 'throw'},
              %Token{type: :true, value: 'true'},
              %Token{type: :false, value: 'false'},
              %Token{type: :nil, value: 'nil'}] = result.tokens
    end

    test "Keywords aren't recognized when part of a longer identifier" do
      result = Lexer.lex("lambda- let- set- orw and/ nott used loopp cond- case- tryy catchh throww truee falsey nill")
      Enum.map(result.tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "String literals are recognized and read properly" do
      result = Lexer.lex(~s("I'm a \\"string\\"" "I'm a seperate string!"))
      assert [%Token{type: :string, value: ~c(I'm a \\"string\\")},
              %Token{type: :string, value: ~c(I'm a seperate string!)}] = result.tokens
    end

    test "Identifier literals are recognized and read properly" do
      result = Lexer.lex("console/log document/write an-identifier20 @global b2-2")

      Enum.map(result.tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "Comments are skipped" do
      result_a = Lexer.lex("""
      (set x 10) ; Insightful comment
      (* @x/n @x/m)
      """)
      assert [%Token{type: :oparen},
              %Token{type: :set},
              %Token{type: :identifier},
              %Token{type: :number},
              %Token{type: :cparen},
              %Token{type: :oparen},
              %Token{type: :*},
              %Token{type: :identifier},
              %Token{type: :identifier},
              %Token{type: :cparen}] = result_a.tokens

      result_b = Lexer.lex("; Some other important comment")
      assert result_b.tokens === []
    end

    test "Line and character numbers are tracked" do
      result = Lexer.lex("""
      ((let z '(1 2 3))
      (let add (lambda (a b) (+ a b)))
      """)

      assert [%Token{line: 1, pos: 1}, %Token{line: 1, pos: 3},
              %Token{line: 1, pos: 5}, %Token{line: 1, pos: 9},
              %Token{line: 1, pos: 11}, %Token{line: 1, pos: 13},
              %Token{line: 1, pos: 15}, %Token{line: 1, pos: 17},
              %Token{line: 1, pos: 19}, %Token{line: 1, pos: 20},
              %Token{line: 1, pos: 22}, %Token{line: 2, pos: 1},
              %Token{line: 2, pos: 3}, %Token{line: 2, pos: 7},
              %Token{line: 2, pos: 11}, %Token{line: 2, pos: 13},
              %Token{line: 2, pos: 20}, %Token{line: 2, pos: 22},
              %Token{line: 2, pos: 24}, %Token{line: 2, pos: 25},
              %Token{line: 2, pos: 28}, %Token{line: 2, pos: 30},
              %Token{line: 2, pos: 33}, %Token{line: 2, pos: 35},
              %Token{line: 2, pos: 36}, %Token{line: 2, pos: 38},
              %Token{line: 2, pos: 40}] = result.tokens
    end
  end
end
