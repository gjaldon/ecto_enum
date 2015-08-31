EctoEnum
========

EctoEnum is an Ecto extension to support enums in your Ecto models.

## Usage

First, we will have to define our enum. We can do this in a separate file since defining
an enum is just defining a module. We do it like:

```elixir
# lib/my_app/ecto_enums.ex

import EctoEnum
defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3
```

Once defined, `EctoEnum` can be used like any other `Ecto.Type` by passing it to a field
in your model's schema block. For example:

```elixir
defmodule User do
  use Ecto.Model

  schema "users" do
    field :status, StatusEnum
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
[registered: 0, active: 1, inactive: 2, archived: 3]
```

## Important links

  * [Documentation](http://hexdocs.pm/ecto_enum)
  * [License](https://github.com/gjaldon/ecto_enum/blob/master/LICENSE)
