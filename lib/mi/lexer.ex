defmodule Mi.Lexer do
  @moduledoc """
  This lexer module converts a sequence of characters into a sequence of
  tokens, removing unnecessary whitespace while doing so. These tokens will later
  be passed to the parser to create an abstract syntax tree which will
  eventually be used to generate Javascript.
  """

  import Mi.Token, only: :macros

  alias Mi.Lexer
  alias Mi.Token

  defstruct errors: [], tokens: [], line: 1, pos: 1

  defp error(lexer, message) do
    "#{lexer.line}:#{lexer.pos}: #{message}"
  end

  defp lex_identifier(expr, acc \\ '')
  defp lex_identifier([char | rest], acc) when is_identifier_literal(char) do
    lex_identifier(rest, acc ++ [char])
  end
  defp lex_identifier(expr, acc) do
    type =
      if Token.keyword?(acc) do
        List.to_atom(acc)
      else
        :identifier
      end

    {:ok, expr, {acc, type}}
  end

  defp lex_string(expr, acc \\ '')
  defp lex_string([?\\, char | rest], acc) do
    lex_string(rest, acc ++ [?\\, char])
  end
  defp lex_string([char | rest], acc) when char === ?" do
    {:ok, rest, {acc, :string}}
  end
  defp lex_string([char | rest], acc) do
    lex_string(rest, acc ++ [char])
  end

  defp lex_number(expr, acc \\ '')
  defp lex_number([char | rest], acc) when is_numeric_literal(char) do
    lex_number(rest, acc ++ [char])
  end
  defp lex_number(expr, acc) do
    {:ok, expr, {acc, :number}}
  end

  defp lex_atom(expr, acc \\ '')
  defp lex_atom([char | rest], acc) when is_atom_literal(char) do
    lex_atom(rest, acc ++ [char])
  end
  defp lex_atom(expr, acc) do
    {:ok, expr, {acc, :atom}}
  end

  defp lex_symbol([?( = char | rest ]), do: {:ok, rest, {char, :oparen}}
  defp lex_symbol([?) = char | rest ]), do: {:ok, rest, {char, :cparen}}
  defp lex_symbol([?+ = char | rest ]), do: {:ok, rest, {char, :+}}
  defp lex_symbol([?- = char | rest ]), do: {:ok, rest, {char, :-}}
  defp lex_symbol([?/ = char | rest ]), do: {:ok, rest, {char, :/}}
  defp lex_symbol([?* = char | rest ]), do: {:ok, rest, {char, :*}}
  defp lex_symbol([?< = char | rest ]), do: {:ok, rest, {char, :<}}
  defp lex_symbol([?> = char | rest ]), do: {:ok, rest, {char, :>}}
  defp lex_symbol([?^ = char | rest ]), do: {:ok, rest, {char, :bxor}}
  defp lex_symbol([?| = char | rest ]), do: {:ok, rest, {char, :bor}}
  defp lex_symbol([?& = char | rest ]), do: {:ok, rest, {char, :band}}
  defp lex_symbol([?' = char | rest ]), do: {:ok, rest, {char, :quote}}
  defp lex_symbol([char | rest]), do: {:error, rest, {char, "unknown symbol #{char}"}}

  defp skip_comment([]), do: []
  defp skip_comment([?\n | _rest] = expr), do: expr
  defp skip_comment([_char | rest]), do: skip_comment(rest)

  def lex(expr),       do: lex(to_charlist(expr), %Lexer{})
  defp lex([], lexer), do: lexer
  defp lex([?\n | rest], lexer) do
    # Newline
    lex(rest, %{lexer | line: lexer.line + 1, pos: 1})
  end
  defp lex([?; | rest], lexer) do
    # Skip comment
    lex(skip_comment(rest), lexer)
  end
  defp lex([char | rest], lexer) when is_whitespace(char) do
    # Skip whitespace
    lex(rest, %{lexer | pos: lexer.pos + 1})
  end
  defp lex([char | rest] = expr, lexer) do
    {status, rest, result} =
      cond do
        is_numeric_literal(char) -> lex_number(expr)
        is_identifier_literal(char) -> lex_identifier(expr)
        char === ?" -> lex_string(rest)
        char === ?: -> lex_atom(rest)
        true ->        lex_symbol(expr)
      end

    {lexer, token} =
      case {status, result} do
        {:ok, {value, type}} ->
          {lexer, Token.new(lexer, value, type)}
        {:error, {value, reason}} ->
          new_lexer = %{lexer | errors: lexer.errors ++ [error(lexer, reason)]}
          {new_lexer, Token.new(lexer, value, :error)}
      end

    lex(rest, %{lexer |
      tokens: lexer.tokens ++ [token],
      pos: lexer.pos + String.length(to_string(token.value))
    })
  end
end
