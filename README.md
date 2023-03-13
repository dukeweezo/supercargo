![alt text](https://github.com/dukeweezo/supercargo/blob/main/supercargo_logo.png)
> su·per·car·go / ˈsoōpərˌkärgō/
>
> n. (pl. -goes or -gos) a representative of the ship's owner on board a merchant ship, responsible for overseeing the cargo.
* Elixir data-mapping library
* Single-source and declarative
* Application-level data integrity (sitting between static analysis and your ORM / database)
* Ideal for any middleware scenarios with one or more heterogeneous / unnormalized datasets from multiple data sources (text files, APIs, message brokers) 
* Currently alpha - any suggestions, questions, so forth (written as issues) are welcome!

Ever seen a dynamic-data API (looking at you, form builder services) providing a response of `{"Field1": "not", "Field2": "very", "Field3": "helpful"}`? Instead of wrangling unmatching fields together amongst procedural code, or building bulky intermediary normalization, **Supercargo** takes a lightweight, data-driven approach with a single *manifest* linking each field to corresponding field and data source. It currently supports an unlimited number of sources → one target.

### Examples (will be changed)
Assume we have the following data from an API & a CSV file:

**JSON response**
```javascript
{"count":12,"results":[{"index":"barbarian","name":"Barbarian","url":"/api/classes/barbarian"},{"index":"bard","name":"Bard","url":"/api/classes/bard"},{"index":"cleric","name":"Cleric","url":"/api/classes/cleric"},{"index":"druid","name":"Druid","url":"/api/classes/druid"},{"index":"fighter","name":"Fighter","url":"/api/classes/fighter"},{"index":"monk","name":"Monk","url":"/api/classes/monk"},{"index":"paladin","name":"Paladin","url":"/api/classes/paladin"},{"index":"ranger","name":"Ranger","url":"/api/classes/ranger"},{"index":"rogue","name":"Rogue","url":"/api/classes/rogue"},{"index":"sorcerer","name":"Sorcerer","url":"/api/classes/sorcerer"},{"index":"warlock","name":"Warlock","url":"/api/classes/warlock"},{"index":"wizard","name":"Wizard","url":"/api/classes/wizard"}]}
```

**CSV file**
```csv
Field1,Field2,Field3
barbarian,Barbarian,/different/url
bard,Bard,/different/url
cleric,Cleric,/different/url
druid,Druid,/different/url
fighter,Fighter,/different/url
monk,Monk,/different/url
paladin,Paladin,/different/url
ranger,Ranger,/different/url
rogue,Rogue,/different/url
thief,Thief,null
sorcerer,Sorcerer,/different/url
warlock,Warlock,/different/url
wizard,Wizard,/different/url
```

**Manifest definition**
```elixir
defmodule Manifest do
  use Supercargo
  
  # Uses list position to map sources ([:api, :csv]) with fields
  #         (api)    (csv)    (target field / key with constraints)
  @index {["index", "Field1"], [:index, :string, ~r/[a-zA-Z]+/]}
  @name  {["name",  "Field2"], [:name,  :string, ~r/[a-zA-Z]+/]}
  @url   {["url",   "Field3"], [:url,   :string, ~r/[a-zA-Z\/]+/]}

  register_mapline [:api, :csv],
    %{
      :name => %{
        elem(@name, 0) => elem(@name, 1)
      },
      :meta => %{
        elem(@index, 0) => elem(@index, 1),
        elem(@url, 0) => elem(@url, 1)
      }
    }
end
```

**Runtime usage**
```elixir
  # ... 
  # enumerating API source
    e_api = Manifest.extract(:api, entry)
    Manifest.meta(e_api)
    # or e.g. insert into a database
  # ...
  |> Enum.reverse
  |> Enum.take(5)
  
  # [ %{index: "wizard", url: "/api/classes/wizard"},
  #   %{index: "warlock", url: "/api/classes/warlock"},
  #   %{index: "sorcerer", url: "/api/classes/sorcerer"},
  #   %{index: "rogue", url: "/api/classes/rogue"},
  #   %{index: "ranger", url: "/api/classes/ranger"} ]

  # ...
  # enumerating CSV source
    e_csv = Manifest.extract(:csv, entry)
    Manifest.meta(e_csv)
    # or e.g. insert into a database
  # ...
  |> Enum.reverse
  |> Enum.take(5)
  
  # [ %{index: "wizard", url: "/different/url"},
  #   %{index: "warlock", url: "/different/url"},
  #   %{index: "sorcerer", url: "/different/url"},
  #   %{index: "thief", url: "null"},
  #   %{index: "rogue", url: "/different/url"} ]
  
  # or e.g. extract all entries at once
  #   e = Manifest.extract(:csv, all_entries)
  # and access them all with 
  #   Manifest.csv(e)

```



### First draft
- [x] Macros
- [x] Parser
- [x] Validator
- [x] Constraints
- [ ] API
  - [x] Runtime `extract/2` and compile-time `extract/1`
  - [x] Category accessors 
  - [ ] Reverse mapping
  - TBD
  
- [ ] Tests (rewritten)

- [ ] Documentation
  - [ ] Module docs
  - [ ] Doctests
  - [ ] Examples
  
### Future
- ? Transformations
- ? Expanded DSL
- Performance optimizations

