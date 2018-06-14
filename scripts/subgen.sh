# Remove temporary files
export INPUTNAME="$1"
export BASENAME="${INPUTNAME%.*}"

# clean intermediate temporaries
rm -f out.flac
rm -f next.flac

# Check if temporary flac exists, if it does, then autosub failed, so no need to regenerate it.
if [ ! -f $BASENAME.flac ]; then
    # Extract mono audio (may fail, for some reason, on some audio streams)
    ffmpeg -i $1 -af "asplit[a],aphasemeter=video=0,ametadata=select:key=lavfi.aphasemeter.phase:value=-0.005:function=less,pan=1c|c0=c0,aresample=async=1:first_pts=0,[a]amix" -ac 1  -f flac out.flac
    if [ $? -ne 0 ]; then
        echo
        echo "********************************************************************"
        echo "ERROR: good mono downmix failed???  Falling back to simple down mix."
        echo 
        rm -f out.flac
        ffmpeg -i $1 -ac 1 -f flac out.flac
    fi
    mv out.flac next.flac

    # Filter out background noise
    ffmpeg -i next.flac -af lowpass=3000,highpass=200 out.flac
    rm -f next.flac
    mv out.flac next.flac

    # Normalise Volume
    ffmpeg-normalize -o out.flac -ofmt flac -c:a flac -pr -p -v next.flac
    mv out.flac $BASENAME.flac
fi

autosub -K $2 -S ja -D en -C 16 -F vtt $BASENAME.flac
if [ $? -ne 0 ]; then
    echo
    echo "********************************************************************"
    echo "ERROR: autosub failed!!!"
else
    rm $BASENAME.flac
fi

# clean intermediate temporaries
rm -f out.flac
rm -f next.flac
