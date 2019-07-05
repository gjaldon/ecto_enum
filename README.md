EctoEnum
========

[![Hex.pm version](https://img.shields.io/hexpm/v/ecto_enum.svg?style=flat)](https://hex.pm/packages/ecto_enum)
[![Hex.pm downloads](https://img.shields.io/hexpm/dt/ecto_enum.svg?style=flat)](https://hex.pm/packages/ecto_enum)
[![Inline docs](http://inch-ci.org/github/gjaldon/ecto_enum.svg?branch=master)](http://inch-ci.org/github/gjaldon/ecto_enum)
[![Build Status](https://travis-ci.org/gjaldon/ecto_enum.svg?branch=master)](https://travis-ci.org/gjaldon/ecto_enum)

EctoEnum is an Ecto extension to support enums in your Ecto models.

## Usage

First, we add `ecto_enum` to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_enum, "~> 1.3"}
  ]
end
```

Run `mix deps.get` to install `ecto_enum`.

### Creating an Ecto Enum with `defenum/2` macro

We will then have to define our enum. We can do this in a separate file since defining
an enum is just defining a module. We do it like:

```elixir
# lib/my_app/ecto_enums.ex

import EctoEnum
defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3
```

Note that we can also use string-backed enums by doing the following:

```elixir
defenum StatusEnum, registered: "registered", active: "active", inactive: "active", archived: "archived"
# short-cut way of using string-backed enums
defenum StatusEnum, ["registered", "active", "inactive", "archived"]
```

Once defined, `EctoEnum` can be used like any other `Ecto.Type` by passing it to a field
in your model's schema block. For example:

```elixir
defmodule User do
  use Ecto.Schema

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

iex> from(u in User, where: u.status == ^:registered) |> Repo.all() |> length
1
```

Passing a value that the custom Enum type does not recognize will result in an error.

### Creating an Ecto Enum by `use`ing `EctoEnum`

Another way to create an Ecto Enum is by `use`ing the `EctoEnum` or the `EctoEnum.Postgres`
modules.

To `use` `EctoEnum` with integer-backed storage:

```elixir
defmodule CustomEnum do
  use EctoEnum, ready: 0, set: 1, go: 2
end
```

To `use` `EctoEnum` with string-backed storage:

```elixir
defmodule CustomEnum do
  use EctoEnum, "ready", "set", "go"
end
```

To `use` `EctoEnum` with Postgres user-defined types:

```elixir
defmodule PostgresType do
  use EctoEnum, type: :new_type, enums: [:ready, :set, :go]
end
```

We can also `use` `EctoEnum.Postgres` directly like:

```elixir
defmodule NewType do
  use EctoEnum.Postgres, type: :new_type, enums: [:ready, :set, :go]
end
```

### Reflection

The enum type `StatusEnum` will also have a reflection function for inspecting the
enum map at runtime.

```elixir
iex> StatusEnum.__enum_map__()
[registered: 0, active: 1, inactive: 2, archived: 3]
iex> StatusEnum.__valid_values__()
[0, 1, 2, 3, :registered, :active, :inactive, :archived, "active", "archived",
"inactive", "registered"]
```

There is also a helper function that leverages the `__valid_values__()` reflection called `valid_value?(value)`.

```elixir
iex> StatusEnum.valid_value?(:registered)
true
iex> StatusEnum.valid_value?("invalid")
false
```

### Using Postgres's Enum Type

[Enumerated Types in Postgres](https://www.postgresql.org/docs/current/static/datatype-enum.html) are now supported. To use Postgres's Enum Type with EctoEnum, use the `defenum/3` macro
instead of `defenum/2`. We do it like:

```elixir
# lib/my_app/ecto_enums.ex

import EctoEnum
defenum StatusEnum, :status, [:registered, :active, :inactive, :archived]
```

The second argument is the name you want to use for the new type you are creating in Postgres.
Note that `defenum/3` expects a list of atoms(could be strings) instead of a keyword
list unlike in `defenum/2`. Another notable difference is that you can no longer
use integers in place of atoms or strings as values in your enum type. Given the
above code, this means that you can only pass the following values:

```elixir
[:registered, :active, :inactive, :archived, "registered", "active", "inactive", "archived"]
```

In your migrations, you can make use of helper functions like:

```elixir
def change do
  StatusEnum.create_type
  create table(:users_pg) do
    add :status, StatusEnum.type()
  end
end
```

`create_type/0`, `type/0` and `drop_type/0` are automatically defined for you in
your custom Enum module.

You can also create the enum in a different schema:
```elixir
defenum StatusEnum, :status, [:registered, :active, :inactive, :archived], schema: "alternative_schema"
```

## Important notes/gotchas

### Postgres
- Keep in mind that `ALTER TYPE ... ADD VALUE` cannot be executed inside a transaction block. This means that running this inside a migration requires you to set to the module attribute `@disable_ddl_transaction` to `true`. For example:

```elixir
defmodule MyApp.Repo.Migrations.AddToGenderEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute "ALTER TYPE gender ADD VALUE IF NOT EXISTS'other'"
  end

  def down do
  end
end
```
- Note that there is no easy way to drop an enum value. It is not supported and you must create a new type without the value. [Here](http://stackoverflow.com/questions/25811017/how-to-delete-an-enum-type-in-postgres) are some work-arounds. Best to avoid having to drop an enum value.

## Important links

  * [Documentation](http://hexdocs.pm/ecto_enum)
  * [License](https://github.com/gjaldon/ecto_enum/blob/master/LICENSE)
