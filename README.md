EctoEnum
========

EctoEnum is an Ecto extension to support enums in your Ecto models.

## Usage

First, we add `ecto_enum` to `mix.exs`:

```elixir
def deps do
  [{:ecto_enum, "~> 0.3.0"}]
end
```

Create new module using `EctoEnum` and set valid enumerables using `enum/1`.

```elixir
# status.ex
defmodule Status do
  use EctoEnum
  enum ~w(registered active inactive archived)
end
```

Once defined, `Status` can be used like any other `Ecto.Type` by passing it to a field
in your model's schema block. For example:

```elixir
defmodule User do
  use Ecto.Model

  schema "users" do
    field :status, Status
  end
end
```

In the above example, the `:status` will behave like an enum and will allow you to
pass an `integer`, `atom` or `string` to it. This applies to saving the model,
invoking `Ecto.Changeset.cast/4`, or performing a query on the status field. Let's
do a few examples:

```elixir
iex> user = Repo.insert!(%User{status: 0})
iex> Repo.get(User, user.id).status
:registered

iex> %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
iex> changes.status
:active

iex> from(u in User, where: u.status == :registered) |> Repo.all() |> length
1
```

Passing a value that the custom Enum type does not recognize will result in an error.

```elixir
iex> Repo.insert!(%User{status: :none})
** (Elixir.EctoEnum.Error) :none is not a valid enum value
```

The enum type `StatusEnum` will also have a reflection function for inspecting the
enum map in runtime.

```elixir
iex> StatusEnum.__enum_map__()
["registered", "active", "inactive", "archived"]

iex> StatusEnum.__meta__()
%{0 => "registered", 1 => "active", 2 => "inactive", 3 => "archived",
  "active" => 1, "archived" => 3, "inactive" => 2, "registered" => 0}
```

## Important links

  * [Documentation](http://hexdocs.pm/ecto_enum)
  * [License](https://github.com/gjaldon/ecto_enum/blob/master/LICENSE)
