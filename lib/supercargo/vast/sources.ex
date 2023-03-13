defmodule Sources do
  defstruct ~w(names structure)a
end

defimpl Generator, for: Sources do
  alias Supercargo.Internal

  """
    Produces flattened intermediary form
      [
        {"field1", :identifier1, :category1, {:string, ~r/[a-zA-Z]{0,50}+/}},
        {"field2", :identifier2, :category2},
        {"field3", :identifier3, :category3},
        ...
      ]
  """

  defp narrow_fields_by_source_index_and_flatten(structure, index) do
    Enum.map(
      structure,
      fn
        {category, entries} when is_map(entries) ->
          Enum.map(
            entries,
            fn
              {fields, [identifier, type_constraint, value_constraint]} ->
                {Enum.at(fields, index), identifier, category,
                 {type_constraint, value_constraint}}

              {fields, identifier} ->
                {Enum.at(fields, index), identifier, category}

              _ ->
                nil
            end
          )

        kv ->
          kv
      end
    )
    |> List.flatten()
  end

  def run(%{structure: structure}, sources) do
    for {source, index} <- Enum.with_index(sources) do
      values = narrow_fields_by_source_index_and_flatten(structure, index)
      Internal.generate_source_ast(%{source: source, values: values})
    end
  end
end
