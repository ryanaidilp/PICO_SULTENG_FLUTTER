# Vendored third-party patches

This directory holds temporary, in-tree copies of upstream packages that
carry an unpublished fix Archipelago depends on. Each subdirectory should
contain its own `README` note (see `mason_logger/PROVENANCE.md`) explaining:

- which upstream package/version this replaces,
- the exact upstream PR/commit the fix comes from,
- why it's vendored instead of pulled from pub.dev or a git dependency,
- the removal condition (what has to happen upstream before this can be
  deleted and the override reverted).

**Do not hand-edit vendored source.** If a fix needs adjusting, update it
upstream (or in the fork the vendored copy was pulled from) and re-vendor,
so the diff against upstream stays traceable.

This convention was introduced for the mason_logger / win32 6.x fix
and is intended to be reused for any future case where a required upstream
fix exists but hasn't been published to pub.dev.
