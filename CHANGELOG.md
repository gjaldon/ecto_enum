# Changelog

## 1.3.2
- EctoEnum now generates typespecs for dialyzer.
- Fixed a bug where the `create_type/0` with the drop was not being created.

## 1.3.1
- Fixed a bug where multiple function clauses of `cast` and `dump` were defined by `EctoEnum.Use`.
This error happens when defining string-backed enums, since multiple function clauses for the string
value is defined.

## 1.3.0
- Refactored internals to make it easier to support `use`ing feature and string-backed enums.
- Add `use`ing functionality so we can use `EctoEnum` or `EctoEnum.Postgres` to define Ecto Enums.
- Support for string-backed enums!

## 1.2.0
- Update formatter config to allow use of `defenum/2` and `defenum/3` without parens.
- Enum function `create_type/0` is now reversible and can be used in `change` in migration files.
- `defenum/4` added which accepts options for creating a Postgres Enum type in a specified schema.
- Added `EctoEnum.validate_enum/3` which is a helper function for validating enum values in a changeset.
- Added `valid_value?/1` to the custom enum which checks if the value passed is a valid enum value.

## 1.0.2

- Fix `defenum/2` and `defenum/3` not accepting variables

## 1.0

- Integration with Ecto 2.0
  If you encounter any compiler or deprecation warnings related to Ecto 2.0,
  please create an issue for it.

- Support for native Postgres Enum. We make use of Postgres' user-defined types

- [Helper functions for migrations](https://github.com/gjaldon/ecto_enum#reflection).
