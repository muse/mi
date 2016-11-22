defmodule Mi.Lexer do
  @moduledoc """
  The lexer converts a sequence of characters into a sequence of tokens,
  removing unnecessary whitespace while doing so. These tokens will later be
  passed to the parser to create an abstract syntax tree which will eventually
  be used to generate Javascript.
  """

  import Mi.Token, only: :macros

  alias Mi.Lexer
  alias Mi.Token

  defstruct tokens: [], line: 1, pos: 1, expr: ''

  @typep token_result :: {atom, charlist, {charlist, atom}}

  @spec error(%Lexer{}, String.t) :: String.t
  defp error(lexer, message) do
    "#{lexer.line}:#{lexer.pos}: #{message}"
  end

  @spec lex_identifier(charlist, charlist) :: token_result
  defp lex_identifier(expr, acc \\ '')
  defp lex_identifier([char | rest], acc) when is_identifier_literal(char) do
    lex_identifier(rest, [char | acc])
  end
  defp lex_identifier(expr, acc) do
    acc = Enum.reverse(acc)
    type =
      if Token.keyword?(acc) do
        List.to_atom(acc)
      else
        :identifier
      end

    {:ok, expr, {acc, type}}
  end

  @spec lex_identifier(charlist, charlist) :: token_result
  defp lex_string(expr, acc \\ '')
  defp lex_string([], _acc) do
    {:error, nil, "unterminated string"}
  end
  defp lex_string([?\\, char | rest], acc) do
    lex_string(rest, [char, ?\\ | acc])
  end
  defp lex_string([?" | rest], acc) do
    {:ok, rest, {Enum.reverse(acc), :string}}
  end
  defp lex_string([char | rest], acc) do
    lex_string(rest, [char | acc])
  end

  @spec lex_number(charlist, charlist) :: token_result
  defp lex_number(expr, acc \\ '')
  defp lex_number([char | rest], acc) when is_numeric_literal(char) do
    lex_number(rest, [char | acc])
  end
  defp lex_number(expr, acc) do
    {:ok, expr, {Enum.reverse(acc), :number}}
  end

  @spec lex_atom(charlist, charlist) :: token_result
  defp lex_atom(expr, acc \\ '')
  defp lex_atom([char | rest], acc) when is_atom_literal(char) do
    lex_atom(rest, [char | acc])
  end
  defp lex_atom(expr, acc) do
    {:ok, expr, {Enum.reverse(acc), :atom}}
  end

  @spec lex_symbol(charlist) :: token_result
  defp lex_symbol(expr) do
    case expr do
      [?( = char | rest] -> {:ok, rest, {char, :oparen}}
      [?) = char | rest] -> {:ok, rest, {char, :cparen}}
      [?+ = char | rest] -> {:ok, rest, {char, :+}}
      [?- = char | rest] -> {:ok, rest, {char, :-}}
      [?/ = char | rest] -> {:ok, rest, {char, :/}}
      [?* = char | rest] -> {:ok, rest, {char, :*}}
      [?<, ?< | rest]    -> {:ok, rest, {'<<', :bshiftl}}
      [?>, ?> | rest]    -> {:ok, rest, {'>>', :bshiftr}}
      [?< = char | rest] -> {:ok, rest, {char, :<}}
      [?> = char | rest] -> {:ok, rest, {char, :>}}
      [?^ = char | rest] -> {:ok, rest, {char, :bxor}}
      [?| = char | rest] -> {:ok, rest, {char, :bor}}
      [?& = char | rest] -> {:ok, rest, {char, :band}}
      [?' = char | rest] -> {:ok, rest, {char, :quote}}
      [char | _rest] ->
        {:error, nil, "unexpected token `#{[char]}'"}
    end
  end

  @spec skip_comment(charlist) :: charlist
  defp skip_comment([]), do: []
  defp skip_comment([?\n | _rest] = expr), do: expr
  defp skip_comment([_char | rest]), do: skip_comment(rest)

  @spec lex(String.t) :: %Lexer{}
  @spec lex(%Lexer{}) :: %Lexer{}
  def lex(%Lexer{expr: []} = lexer) do
    {:ok, %{lexer | tokens: Enum.reverse(lexer.tokens)}}
  end
  def lex(%Lexer{expr: [?\n | rest]} = lexer) do
    # Newline
    lex(%{lexer | expr: rest, line: lexer.line + 1, pos: 1})
  end
  def lex(%Lexer{expr: [?; | rest]} = lexer) do
    # Skip comment
    lex(%{lexer | expr: skip_comment(rest)})
  end
  def lex(%Lexer{expr: [char | rest]} = lexer) when is_whitespace(char) do
    # Skip whitespace
    lex(%{lexer | expr: rest, pos: lexer.pos + 1})
  end
  def lex(%Lexer{expr: [char | rest]} = lexer) do
    {status, rest, result} =
      cond do
        is_numeric_literal(char) -> lex_number(lexer.expr)
        is_start_of_identifier(char) -> lex_identifier(lexer.expr)
        char === ?" -> lex_string(rest)
        char === ?: -> lex_atom(rest)
        true ->        lex_symbol(lexer.expr)
      end

    case {status, result} do
      {:ok, {value, type}} ->
        token = Token.new(lexer, value, type)
        lex(%{lexer |
              expr: rest,
              tokens: [token | lexer.tokens],
              pos: lexer.pos + (to_string([token.value]) |> String.length)
            })
      {:error, reason} ->
        {:error, error(lexer, reason)}
    end
  end
  def lex(expr), do: lex(%Lexer{expr: to_charlist(expr)})
end
