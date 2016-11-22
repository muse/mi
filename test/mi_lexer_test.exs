defmodule MiLexerTest do
  alias Mi.Lexer
  alias Mi.Token
  use   ExUnit.Case

  describe "&Lexer.lex/1" do
    test "Keywords are recognized" do
      {:ok, tokens} = Lexer.lex("""
      lambda define or and not use loop cond case try catch throw true false
      nil
      """)
      assert [%Token{type: :lambda, value: 'lambda'},
              %Token{type: :define, value: 'define'},
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
              %Token{type: :nil, value: 'nil'}] = tokens
    end

    test "Keywords aren't recognized when part of a longer identifier" do
      {:ok, tokens} = Lexer.lex("""
      lambda- definee orw and/ nott used loopp cond- case- tryy catchh throww
      truee falsey nill
      """)
      Enum.map(tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "String literals are recognized and read properly" do
      {:ok, tokens} = Lexer.lex(~s("I'm Å \\"string\\"" "I'm a seperate string!"))

      assert [%Token{type: :string, value: ~c(I'm Å \\"string\\")},
              %Token{type: :string, value: ~c(I'm a seperate string!)}] = tokens
    end

    test "Unterminated strings error" do
      {:error, reason} = Lexer.lex(~s("I'm an unterminated \\"string\\" over
      multiple lines))

      assert reason === "1:1: unterminated string"
    end

    test "Identifier literals are recognized and read properly" do
      {:ok, tokens} = Lexer.lex("""
      console/log document/write an-identifier20 @global b2-2 simpleident x y z
      """)

      Enum.map(tokens, fn(token) -> assert token.type === :identifier end)
    end

    test "Comments are skipped" do
      {:ok, tokens_a} = Lexer.lex("""
      (define x 10) ; Insightful comment
      (* @x/n @x/m)
      """)
      assert [%Token{type: :oparen},
              %Token{type: :define},
              %Token{type: :identifier},
              %Token{type: :number},
              %Token{type: :cparen},
              %Token{type: :oparen},
              %Token{type: :*},
              %Token{type: :identifier},
              %Token{type: :identifier},
              %Token{type: :cparen}] = tokens_a

      {:ok, tokens_b} = Lexer.lex("; Some other important comment")
      assert tokens_b === []
    end

    test "Line and character numbers are tracked" do
      {:ok, tokens} = Lexer.lex("""
      ((define z '(1 2 3))
      (define add (lambda (a b) (+ a b)))
      """)

      [%Mi.Token{line: 1, pos: 1}, %Mi.Token{line: 1, pos: 2},
       %Mi.Token{line: 1, pos: 3}, %Mi.Token{line: 1, pos: 10},
       %Mi.Token{line: 1, pos: 12}, %Mi.Token{line: 1, pos: 13},
       %Mi.Token{line: 1, pos: 14}, %Mi.Token{line: 1, pos: 16},
       %Mi.Token{line: 1, pos: 18}, %Mi.Token{line: 1, pos: 19},
       %Mi.Token{line: 1, pos: 20}, %Mi.Token{line: 2, pos: 1},
       %Mi.Token{line: 2, pos: 2}, %Mi.Token{line: 2, pos: 9},
       %Mi.Token{line: 2, pos: 13}, %Mi.Token{line: 2, pos: 14},
       %Mi.Token{line: 2, pos: 21}, %Mi.Token{line: 2, pos: 22},
       %Mi.Token{line: 2, pos: 24}, %Mi.Token{line: 2, pos: 25},
       %Mi.Token{line: 2, pos: 27}, %Mi.Token{line: 2, pos: 28},
       %Mi.Token{line: 2, pos: 30}, %Mi.Token{line: 2, pos: 32},
       %Mi.Token{line: 2, pos: 33}, %Mi.Token{line: 2, pos: 34},
       %Mi.Token{line: 2, pos: 35}] = tokens
    end
  end
end
