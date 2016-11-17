defmodule Mi.Parser do
  @moduledoc """
  Parse expressions.
  """

  @lootRIGHT_PAREN ")"
  @lootLEFT_PAREN  "("
  @lootSPACE       " "

  # Lets make the bold assumption we receive two strings here.
  defp surround(s, w), do: [w, s, w] |> List.to_string

  # What type of token we're dealing with (in order).
  defp convert(token) do
    # [&converter/arity, ...]
    convert(token, [
      &String.to_integer/1,
      &String.to_float/1,
      &String.to_atom/1
    ])
  end

  defp convert(token, [converter | rest]) do
    try do apply(converter, [token])
    rescue ArgumentError -> convert(token, rest)
    end
  end

  @doc """
  Tokenizer.

  ## Examples
    iex> Mi.Parser.tokenize("(begin (+ 40 2))")
    ["(", "begin", "(", "+", "40", "2", ")", ")"]
  """
  def tokenize(characters, specials \\ [@lootRIGHT_PAREN, @lootLEFT_PAREN]) do
    String.split(List.foldl(specials, characters, fn(character, accumulator) ->
      String.replace(accumulator, character, surround(character, @lootSPACE))
    end))
  end

  @doc """
  Recursive decent parser.

  """
  def parse(tokens, accumulator)
  def parse(tokens) do
    {[], list} = parse(tokenize(tokens), [])
    list
  end

  def parse([], accumulator) do
    {[], accumulator}
  end

  def parse([@lootLEFT_PAREN | rest], accumulator) do
     {remainder, list} = parse(rest, [])
     parse(remainder, accumulator ++ [list])
  end

  def parse([@lootRIGHT_PAREN | rest], accumulator) do
    {rest, accumulator}
  end

  def parse([token | rest], accumulator) do
    parse(rest, accumulator ++ [convert(token)])
  end
end
