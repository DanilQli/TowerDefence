# Mortar (tower 18) automated checks

Run the project-level test suite from a shell while the Godot editor is closed:

```sh
GODOT_BIN=/path/to/godot ./Tests/run_mortar_tests.sh
```

The runner requires Godot 4.x. It performs a full headless import/compile pass, temporarily switches the project main scene to the test scene, runs the checks, and restores `project.godot` even on failure or interruption. It creates a temporary lock directory to prevent concurrent runs. Run it with the editor closed.

Alternatively, open `Tests/MortarTowerTests.tscn` in Godot and use **Run Current Scene (F6)**. The suite checks that the project menu scene parses and instantiates, then verifies factory/catalog integration, range setup, center-vs-edge area damage, Concussive Fuse stun and boss slow, all three cluster fragments, the real shell-flight/impact/cooldown path, mastery and achievement progression, localization keys, audio registrations/files, and stage/skin art resources.
