#!/bin/sh

FLAGS="-fversion=PANDORA -frelease -fno-section-anchors -c -O2 -pipe"

rm import/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/gr/*.o*

cd import
$PNDSDK/bin/pandora-gdc $FLAGS *.d
cd ..

cd src/abagames/util
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

cd src/abagames/util/sdl
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../../import -I../../.. *.d
cd ../../../..

cd src/abagames/gr
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

$PNDSDK/bin/pandora-gdc -o Gunroar -s -Wl,-rpath-link,$PNDSDK/usr/lib -L$PNDSDK/usr/lib -lGLU -lGL -lSDL_mixer -lmad -lSDL -lts import/*.o* src/abagames/util/*.o* src/abagames/util/sdl/*.o* src/abagames/gr/*.o*
