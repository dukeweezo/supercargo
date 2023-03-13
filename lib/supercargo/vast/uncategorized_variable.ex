defmodule UncategorizedVariable do
  defstruct [:fields, :identifier]
end

defimpl Generator, for: UncategorizedVariable do
  alias Supercargo.Internal.Accessors

  def run(%{fields: fields, identifier: identifier}, sources) do
    # TD: narrow by source if length(fields) > 1
    Accessors.generate_uncategorized_variable_ast(%{
      kv: {fields, identifier},
      identifier: identifier
    })
  end
end
