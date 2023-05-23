# mkvtoolkit

An ubuntu image with mkvtoolnix installed and a couple of scripts to automate batch video files edition.

&nbsp;

## Description

The idea is to have a docker container with the tools to make batch file edition over mkv files.

For this the *runner.sh* script handles the container creation, and tools execution.

To execute the *runner.sh* script you can call it whitout arguments and it will display an **usage** message.   But to operate it should be called with at least two arguments, first a *command* and a *path* to the folder where the mkv files are.

The *runner.sh* script build the image if it is not exists on the first run, using the Dockerfile in the repo, installing mkvtoolnix and copying the mkvcli.sh script as entryopint.   After the image is built, a new container will start, mounting the videos path in the container and executing the tools in that path.

The available commands are:
- **showTracks**: This command will display a line for every mkv file found in the path, with the type, number and name on the track, indicating also if the default track's flag is set.
- **setTitle**: Sets the title of the mkv file based on the file name.
- **setDefaultTrack**: Based on the args provided, it will set the default track flag on one of the track by type.

More details about de command will be found in the usage output of the *runner.sh* script.
