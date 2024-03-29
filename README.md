# mkvtoolkit

An ubuntu image with mkvtoolnix installed and a couple of scripts to automate batch video files edition.

&nbsp;

## Description

The idea is to have a docker container with the tools to make batch file edition over mkv files.

So the **runner.sh** script handles the container creation, and tools execution.

To execute the **runner.sh** script you can call it whitout arguments and it will display an **usage** message.   But to operate it should be called with at least two arguments, first a *command* and a *path* to the folder where the video files are.


The **runner.sh** script build the image if it is not exists on the first run, using the Dockerfile in the repo, installing mkvtoolnix and copying the mkvcli.sh script as entryopint.   After the image is built, a new container will start, mounting the videos path in the container and executing the tools in that path.

The available commands are:
- **showTracks**: This command will display a line for every supported video file found in the path, with the type, number and name on the track, indicating also if the default track's flag is set.
   - **example**: runner.sh *[videos_path]* showTracks
- **setTitle**: Sets the title of the .mkv file based on the file name.
   - **example**: runner.sh *[videos_path]* setTitle
- **setDefaultTrack**: Based on the args provided, it will set the default track flag on one of the track by type.
   - **example**: runner.sh *[videos_path]* setDefaultTrack "S:English"  // set subs track named English as default
   - **example**: runner.sh *[videos_path]* setDefaultTrack "S:English,A:English"  // set subs track and audio named English as defaults
   - **example**: runner.sh *[videos_path]* setDefaultTrack "F:S01E02;S:English"  // set subs track named English as default in file that match regular expression
- **setTrackName**: Change the name of a track in one or all files.
   - **example**: runner.sh *[videos_path]* setTrackName
- **convert**: Searches for .mp4 or .avi files and .srt in the same folder, to create a .mkv file with the files as tracks.
   - **example**: runner.sh *[videos_path]* convert
- **addTrack**: Add a new track to the mkv file, at this point only subtitles are available to be added.
   - **example**: runner.sh *[videos_path]* addTrack


&nbsp;

## Usage


### showTracks

```sh
$ sh runner.sh ~/Downloads/Videos/ showTracks
> Starting new container
01
video_001.mkv
Video 1
V=*1:und A=*2:en S=3:en;4:SDH
02
video_002.mkv
Video 2
V=*1:und A=*2:en S=3:en;4:SDH
03
video_003.mp4
04
video_004.mkv
Video 4
V=*1:und A=*2:en S=3:en;4:SDH
```

The output shows all video files in the selected path, that includes .mlv, .avi. mp4 files, and over the .mkv files additional information will be displayed.  For any video file the following information will be displayed:
```sh
File number
File Name
MKV title setted property
MKV tracks information
```

The traks information line is separated in three types, the ones starting with the V means Video tracks, A for audio and S for subtitles.   For each type the track number and name is displayed, and an asteric (*) in front of the track number, means default track.




&nbsp;



```sh
% ./mkvcli.sh convert
> Converting files to mkv
> Analizing 'Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius'
- Executing 'mkvmerge -o "/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.mkv" "/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.avi" --title "Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius"'
mkvmerge v78.0 ('Running') 64-bit
'/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.avi': Using the demultiplexer for the format 'AVI'.
'/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.avi' track 0: Using the output module for the format 'MPEG-4'.
'/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.avi' track 1: Using the output module for the format 'MPEG-1/2 Audio Layer II/III'.
The file '/videos/Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.mkv' has been opened for writing.
The cue entries (the index) are being written...
Multiplexing took 30 seconds.


> Analizing 'Saturday Night Live - S49E06 - Emma Stone & Noah Kahan'
- Executing 'mkvmerge -o "/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.mkv" "/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.avi" --title "Saturday Night Live - S49E06 - Emma Stone & Noah Kahan"'
mkvmerge v78.0 ('Running') 64-bit
'/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.avi': Using the demultiplexer for the format 'AVI'.
'/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.avi' track 0: Using the output module for the format 'MPEG-4'.
'/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.avi' track 1: Using the output module for the format 'MPEG-1/2 Audio Layer II/III'.
The file '/videos/Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.mkv' has been opened for writing.
The cue entries (the index) are being written...
Multiplexing took 31 seconds.
```

```sh
./mkvcli.sh showTracks
01:Saturday Night Live - S49E01 - Pete Davidson & Ice Spice.mkv
-
V=*1:und A=*2:eng S=*3:English
02:Saturday Night Live - S49E02 - Bad Bunny.mkv
-
V=*1:und A=*2:eng S=*3:English
03:Saturday Night Live - S49E03 - Nate Bargatze & Foo Fighters.mkv
torrentgalaxy.to | Saturday.Night.Live.S49E03.WEB.x264-TORRENTGALAXY
V=*1:und A=*2:Saturday.Night.Live.S49E03.WEB.x264-TORRENTGALAXY S=*3:Saturday.Night.Live.S49E03.WEB.x264-TORRENTGALAXY
04:Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.avi
05:Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.mkv
Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius
V=*1:und A=*2:und S=
06:Saturday Night Live - S49E05 - Jason Mamoa & Tate McRae.mkv
torrentgalaxy.to | Saturday.Night.Live.S49E05.WEB.x264-TORRENTGALAXY
V=*1:und A=*2:Saturday.Night.Live.S49E05.WEB.x264-TORRENTGALAXY S=*3:Saturday.Night.Live.S49E05.WEB.x264-TORRENTGALAXY
07:Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.avi
08:Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.mkv
Saturday Night Live - S49E06 - Emma Stone & Noah Kahan
V=*1:und A=*2:und S=
09:Saturday Night Live - S49E07 - Adam Driver & Olivia Rodrigo.mkv
torrentgalaxy.to | Saturday.Night.Live.S49E07.WEB.x264-TORRENTGALAXY
V=*1:und A=*2:Saturday.Night.Live.S49E07.WEB.x264-TORRENTGALAXY S=*3:Saturday.Night.Live.S49E07.WEB.x264-TORRENTGALAXY
10:Saturday Night Live - S49E08 - Kate McKinnon & Billie Eilish.mkv
-
V=*1:und A=*2:eng S=3:English
```

```sh
% ./mkvcli.sh setTrackName "F:*;T:3;English"
> Setting file track name:
> Editing file 'Saturday Night Live - S49E07 - Adam Driver & Olivia Rodrigo.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
> Editing file 'Saturday Night Live - S49E05 - Jason Mamoa & Tate McRae.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
> Editing file 'Saturday Night Live - S49E02 - Bad Bunny.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
> Editing file 'Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.mkv"'
The file is being analyzed.
Error: No track corresponding to the edit specification '3' was found. The file has not been modified.
> Editing file 'Saturday Night Live - S49E08 - Kate McKinnon & Billie Eilish.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
> Editing file 'Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.mkv"'
The file is being analyzed.
Error: No track corresponding to the edit specification '3' was found. The file has not been modified.
> Editing file 'Saturday Night Live - S49E03 - Nate Bargatze & Foo Fighters.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
> Editing file 'Saturday Night Live - S49E01 - Pete Davidson & Ice Spice.mkv"'
The file is being analyzed.
The changes are written to the file.
Done.
```

```sh
runner.sh "/Volumes/Backups/Series/1975 - Lorne Michaels - Saturday Night Live/S49" showTracks
> Starting new container
01 Saturday Night Live - S49E01 - Pete Davidson & Ice Spice.mkv
   Saturday Night Live - S49E01 - Pete Davidson & Ice Spice
V=*1:und A=*2:English S=*3:English
02 Saturday Night Live - S49E02 - Bad Bunny.mkv
   Saturday Night Live - S49E02 - Bad Bunny
V=*1:und A=*2:English S=*3:English
03 Saturday Night Live - S49E03 - Nate Bargatze & Foo Fighters.mkv
   Saturday Night Live - S49E03 - Nate Bargatze & Foo Fighters
V=*1:und A=*2:English S=*3:English
04 Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius.mkv
   Saturday Night Live - S49E04 - Timothee Chalamet & Boygenius
V=*1:und A=*2:English S=
05 Saturday Night Live - S49E05 - Jason Mamoa & Tate McRae.mkv
   Saturday Night Live - S49E05 - Jason Mamoa & Tate McRae
V=*1:und A=*2:English S=*3:English
06 Saturday Night Live - S49E06 - Emma Stone & Noah Kahan.mkv
   Saturday Night Live - S49E06 - Emma Stone & Noah Kahan
V=*1:und A=*2:English S=
07 Saturday Night Live - S49E07 - Adam Driver & Olivia Rodrigo.mkv
   Saturday Night Live - S49E07 - Adam Driver & Olivia Rodrigo
V=*1:und A=*2:English S=*3:English
08 Saturday Night Live - S49E08 - Kate McKinnon & Billie Eilish.mkv
   Saturday Night Live - S49E08 - Kate McKinnon & Billie Eilish
V=*1:und A=*2:English S=3:English
```

```sh
bash mkvcli.sh addTrack
> Adding track to mkv file:
+ Write file number (* to all): _ 9
> Adding track to /videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.mkv
>> Found subtitle /videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.vtt, add as new track? [y/n]_ y
>> Subtitle file content:
---
WEBVTT

00:00.643 --> 00:02.910
Este es un momento
emocionante en el mundo.

00:02.945 --> 00:05.830
- Un momento emocionante.
- Si tú aceptas testificar,

00:05.830 --> 00:07.697
yo testificaré que entré
a la cadena de custodia

00:07.733 --> 00:08.865
---
>> Add subtitle lang code: (ENG|SPA|..) _ SPA
---
>> Add subtitle lang code name: (English SDH|Español|..) _ Esp
>> Adding sub: /videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.vtt
> Executing:
> mkvmerge -o '/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.converted.mkv' '/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.mkv'  --language 0:SPA --track-name 0:Esp '/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.vtt'
ejecutar? [y/n] _ y

mkvmerge v78.0 ('Running') 64-bit
'/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.mkv': Using the demultiplexer for the format 'Matroska'.
'/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.vtt': Using the demultiplexer for the format 'WebVTT subtitles'.
'/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.mkv' track 0: Using the output module for the format 'AVC/H.264'.
'/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.mkv' track 1: Using the output module for the format 'AC-3'.
'/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.vtt' track 0: Using the output module for the format 'WebVTT subtitles'.
The file '/videos/Mr. Robot - S01E09 - eps1.8_m1rr0r1ng.qt.converted.mkv' has been opened for writing.
The cue entries (the index) are being written...
Multiplexing took 17 seconds.
```