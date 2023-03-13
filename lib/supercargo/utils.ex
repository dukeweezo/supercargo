defmodule Supercargo.Utils do
  def construct_atomized_name(parts) do
    Enum.reduce(parts, acc = "", fn part, acc ->
      case part do
        part when is_atom(part) ->
          acc <> Atom.to_string(part)

        part when is_bitstring(part) ->
          acc <> part
      end
    end)
    |> String.to_atom()
  end
end
