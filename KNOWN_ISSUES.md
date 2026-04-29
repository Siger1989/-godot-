# KNOWN ISSUES

## Godot 4.3 headless dummy renderer noise

When validation scripts run with `--headless`, Godot 4.3 may print repeated lines like:

```text
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

The current validation scripts can still pass with exit code `0`. Treat this as headless renderer shutdown noise unless a validation script prints `*_FAILED` or exits non-zero.

This has not appeared as a gameplay logic failure in the checked scenes.
