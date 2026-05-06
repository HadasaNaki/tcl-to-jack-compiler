# Stage 3 Jack Project

## What this project does

This Jack application draws two selectable shapes on the screen and lets the user:
- switch between the shapes
- move the active shape in all four directions
- rotate it by 90, 180, or 270 degrees
- grow or shrink it
- track the number of actions performed on each object
- display a final summary when the user quits

## Files

- `Main.jack` - main loop, keyboard handling, final summary
- `ShapeA.jack` - triangle-based shape with rotation and scaling
- `ShapeB.jack` - house/marker shape with rotation and scaling

## Controls

- `1` - select ShapeA
- `2` - select ShapeB
- Arrow keys - move the active shape
- `R` - rotate 90 degrees
- `E` - rotate 180 degrees
- `T` - rotate 270 degrees
- `+` - grow
- `-` - shrink
- `Q` / `ESC` - quit and print the summary

## Build and run

1. Copy the OS VM files from `nand2tetris/tools/OS/` into this folder.
2. Compile the folder with JackCompiler.
3. Load the resulting VM folder into the VM Emulator.
4. Set the emulator to No Animation for the cleanest rendering.

## Notes

- The objects are implemented as Jack classes, one class per file.
- Action tracking is per object and is incremented only for move/rotate/scale commands.
- The program is designed to be easy to explain in a walkthrough: state lives in the shape objects, and input handling stays in Main.
