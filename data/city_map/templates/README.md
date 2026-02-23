# Noir Protocol Templates

These templates define optional fields for CityMap modernization without breaking existing `v2.1.0` levels.

## New fields

- `ui.graph_fill_ratio`: target graph area share (for fullscreen graph + dossier layout logic).
- `ui.node_hit_target_px`: minimum click/touch target.
- `numpad`: in-game numeric input options.
- `traffic`: visual packet animation config.
- `schedule_overlay`: runtime schedule indicator behavior.
- `edges[].bend`: edge curvature in range `[-1.0, 1.0]`.

## Compatibility

- Existing scenes can safely ignore unknown fields.
- `edges[].bend` defaults to `0.0` when absent.
- `schedule` behavior remains backward compatible with current Mode C rules.
