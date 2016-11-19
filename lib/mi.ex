defmodule Mi do
  @moduledoc """
  """

  alias Mi.{Parser, Lexer}

  @expression """
    ((let x 5)
     (let y 10)
     (let z '(1 2 3))
     (let add (lambda (a b) (+ a b)))


    (set @x (object (:n 1 :m 2)))     ;=> var x = {"n": 1, "m": 2};
    (* @x/n @x/m)                     ;=> 2

    (case false (false 1) (true 2) 10)
    (cond (false 1) (true 2))

    (document/element-create! "div")
    (document/append-element "div")
  """

  def main(_args) do
    #Lexer.lex(@expression)
    #|> IO.inspect

    IO.inspect(@expression)
    Lexer.lex("(#$)")
    |> IO.inspect(limit: :infinity)

    # Lexer.lex("(')(')")
    # |> IO.inspect

    # Lexer.is_alphabetic("x")
    # |> IO.inspect

    # Lexer.split("(begin\t(* 2 2)\n)")
    # |> IO.inspect
    # Parser.parse(REPL.read "repl> ")
    # |> IO.inspect
  end
end
