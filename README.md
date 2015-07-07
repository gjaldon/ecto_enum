EctoEnum
========

EctoEnum is an Ecto extension to support enums in your Ecto models.

## Usage

Use the `Ecto.Enum` module in your model before using `Ecto.Model` like below:

```elixir
defmodule MyApp.User do
  use Ecto.Enum
  use Ecto.Model

  schema "users" do
    enum :status, [registered: 0, active: 1, inactive: 2, archived: 3]
  end
end
```

You declare an enum field by using the `enum/2` macro inside the schema block.
This macro generates a `status` integer field and an `enum_status` virtual field.
The `status` field returns an integer while `enum_status` returns an atom such as
`:register`.

Helper functions are also provided. For the above `MyApp.User` model, we can check
if the user model is registered by doing `MyApp.User.registered?(user)`. You can
check for the user's other status in the same way.

Setting `enum_status` for the user model is as good as setting its `status` when
inserting or updating the model. For example:

```elixir
iex> user = Repo.insert!(%User{enum_status: :registered})
iex> user.status
0
iex> user = Repo.update!(%{user|enum_status: :active})
iex> user.status
2
```

Inspecting a model's enum field's mapping in runtime is possible by invoking
`__enums__/1`. It works like:

```elixir
iex> User.__enums__(:status)
[registered: 0, active: 1, inactive: 2, archived: 3]
```

This can be useful for running queries since `Ecto.Repo.Queryable` does not know
about enums unlike `Ecto.Model`. For example:

```elixir
iex> registered = User.__enums__(:status)[:registered]
0
iex> from(u in User, where: u.status == ^registered)
```

## Important links

  * [Documentation](http://hexdocs.pm/ecto_enum)
  * [License](https://github.com/gjaldon/ecto_enum/blob/master/LICENSE)
