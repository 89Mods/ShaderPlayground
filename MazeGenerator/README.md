# Procedural Maze Generator
This is a shader that runs in a CRT and randomly generates a maze. I created this to see if it was possible to use a stack in a CRT.

# Setup
Install the CRT_GenericInputLayer shader also found in this repository.
Set up the required Avatar parameters.
![a](https://raw.githubusercontent.com/89Mods/ShaderPlayground/main/MazeGenerator/parameterSetup.png)

Copy both animation layers from the `ReferenceAnimator` controller into your FX animator, not forgetting to add the three avatar parameters to the controller's parameter list first.
The animations are WD Off - compatible. Just uncheck that checkbox on all the nodes if your avatar uses WD Off.
Add a sub-menu entry to the `MazeMenu` somewhere in your expressions menu.
Optional: If you want the generated mazes to be unique to your avatar, select the `MazeGenMat` material, and change both Seed 1 and Seed 2 to different 7-digit numbers.
The system is now ready to go. To display the generated mazes on your avatar, drop the `MazeOutputCRT` texture into any texture slot on any material of your choosing. `SampleMazeMat` and `MazeOutputPoi` are two included examples of this.

# Usage
To use the system, bring up the maze generator's expressions menu. First, toggle "Enable Maze Gen" on, **and don't forget to turn it back of when you're done generating mazes!** This parameter acts as a safeguard to prevent the generator from accidentally triggering, which might happen for people who are out of range of the GrabPass input layer on your avatar.
Next, press "Gen Maze". No need to hold it. The generator will start in just a second, and you'll be able to watch it go on the output texture.
To generate a different maze, change the "Maze Seed" value to anything you want.

