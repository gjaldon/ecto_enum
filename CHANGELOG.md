# Changelog

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
