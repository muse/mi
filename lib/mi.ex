defmodule Mi do
  import Mi.Utils

  alias Mi.{Parser, Lexer}

  def main(_args) do
    input =
      case IO.read(:stdio, :all) do
        {:error, reason} -> fatal_error("mi", reason)
        data -> data
      end

    tokens =
      case Lexer.lex(input) do
        {:error, reason} -> fatal_error("lexer", reason)
        {:ok, lexer}     -> lexer.tokens
      end

    IO.inspect tokens
  end
end
