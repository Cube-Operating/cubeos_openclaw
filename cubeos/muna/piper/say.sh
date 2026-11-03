#!/bin/sh
# OpenClaw tts-local-cli: say.sh <output.wav> <text>
printf '%s\n' "$2" | exec /home/ugoji-harry/.local/piper/piper/piper --quiet --model /home/ugoji-harry/.local/piper/voices/en_US-lessac-medium.onnx --output_file "$1"
