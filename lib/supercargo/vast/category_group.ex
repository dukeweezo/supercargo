defmodule Category.Group do
  defstruct [:entries, :name]
end

defimpl Generator, for: Category.Group do
  """
    Produces flattened intermediary form
      [
        {"field1", :identifier1},
        {"field2", :identifier2},
        {"field3", :identifier3},
        ...
      ]
  """

  defp narrow_fields_by_source_index_and_flatten(entries, index) do
    for %{fields: fields, identifier: identifier} <- entries do
      {Enum.at(fields, index), identifier}
    end
  end

  def run(%{name: category_name, entries: entries}, sources) do
    for {source, index} <- Enum.with_index(sources) do
      values = narrow_fields_by_source_index_and_flatten(entries, index)

      [
        Supercargo.Internal.generate_category_ast(%{
          source: source,
          category: category_name,
          values: values
        }),
        Supercargo.generate_category_ast(%{source: source, category: category_name})
      ]
    end
  end
end

defimpl Enumerable, for: Category.Group do
  def reduce(map, acc, fun) do
    {:cont, new_acc} = acc
    map = Map.from_struct(map)
    Enum.reduce(map, new_acc, fun)
  end
end
