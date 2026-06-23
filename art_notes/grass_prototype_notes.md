# Grass Prototype Notes

This prototype is intentionally focused on grass only.

- Open the folder in Godot 4.7.
- Run `scenes/GrassWorld.tscn`.
- The scene creates low-poly ground, dense grass clumps, wind animation, soft sky, fog, and distant trees.
- Camera controls: `A/D` orbit, `W/S` tilt, `Q/E` zoom.

Main tuning points are exported on the `GrassWorld` root node:

- `grass_count`
- `field_radius`
- `grass_height`
- `wind_strength`
- `wind_speed`

