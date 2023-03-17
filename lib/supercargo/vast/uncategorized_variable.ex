defmodule UncategorizedVariable do
  defstruct [:fields, :identifier]
end

defimpl Generator, for: UncategorizedVariable do
  alias Supercargo.Internal

  def run(%{fields: fields, identifier: identifier}, sources) do
    # TD: narrow by source if length(fields) > 1

    for {source, index} <- Enum.with_index(sources) do
      [
        Internal.generate_uncategorized_variable_ast(%{kv: {fields, identifier}, identifier: identifier}),
      	Supercargo.generate_uncategorized_variable_ast(%{source: source, kv: {fields, identifier},identifier: identifier})
    	]
    end

    
  end
end
