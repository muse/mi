defmodule Mi.Token do
  @moduledoc """
  A token is a categorization of text to be used by the parser.
  """

  alias Mi.Token

  defstruct [:value, :type, :line, :pos]

  defmacro is_whitespace(c) do
    quote do: unquote(c) in [?\t, ?\s, ?\r]
  end

  defmacro is_atom_literal(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or
      unquote(c) in [?_, ?-, ?+, ?-, ?*, ?/, ?%, ?^, ?@, ?!, ?&, ?|]
  end

  defmacro is_numeric_literal(c) do
    quote do: unquote(c) in ?0..?9 or unquote(c) === ?.
  end

  defmacro is_identifier_literal(c) do
    quote do: unquote(c) in ?a..?z or unquote(c) in ?A..?Z or
      unquote(c) in [?_, ?-, ?@, ?/, ?!]
  end

  @keywords [
    'lambda',
    'let',
    'set',
    'or',
    'and',
    'not',
    'use',
    'loop',  # for, while
    'cond',  # if
    'case',
    'try',
    'catch',
    'throw',
    'true',
    'false',
    'nil',
  ]

  def new(lexer, value, type) do
    %Token{
      value: value,
      type: type,
      pos: lexer.pos,
      line: lexer.line
    }
  end

  @doc """
  Check if a charlist is a keyword.

  ## Example:
  iex> Mi.Lexer.Token.keyword?('lambda')
  true

  """
  def keyword?(value), do: value in @keywords
end
