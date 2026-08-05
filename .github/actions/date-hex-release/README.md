# Date Hex release action
Creates a source-controlled release-version commit using the shared date convention:

- Hex version: `YY.MMDD.SEQUENCE`, for example `26.805.1`
- Git tag: `YYYY.MM.DD.SEQUENCE`, for example `2026.08.05.01`

The action only creates the version commit and exposes both identifiers. The calling workflow owns publication, credentials, tagging, and any environment protection.

## Inputs

- `version_file`: Mix project file containing exactly one literal `version: "..."` or `@version "..."` declaration.
- `commit_message_prefix`: Release commit prefix. Defaults to `[DEPLOY]`.
- `source_ref_file`: Optional Mix project file containing exactly one literal `@source_ref "..."` declaration to update with the Git tag.

## Outputs

- `hex_version`
- `git_tag`

## Use from another repository

Pin a released immutable tag of this repository:

```yaml
- id: version
  uses: algorocom/paginator/.github/actions/date-hex-release@2026.08.05.01
  with:
    version_file: mix.exs
```

The caller must check out its repository with tags, configure a Git author, and grant its workflow `contents: write` before invoking the action.
