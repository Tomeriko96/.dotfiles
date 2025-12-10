#!/usr/bin/env bash

# Simple MPV-based internet radio controller for Polybar

RADIO_INDEX_FILE="/tmp/current_radio_index"
MPV_SOCKET="/tmp/mpv-radio-socket"
TRACK_INFO_FILE="/tmp/radio_track_info.txt"

# Icons (require Nerd Fonts or similar)
PLAY_ICON=""
PAUSE_ICON=""
STOP_ICON=""

# Station list: "URL|Name"
STATIONS=(
  "http://www.rs.mizrahit.fm:7777/|Mizrahit"
  "http://102.livecdn.biz/102fm_aac|Radio Tel Aviv"
  "http://kanliveicy.media.kan.org.il/icy/749625_mp3|Kan Gimmel"
  "http://glzwizzlv.bynetcdn.com/glz_mp3|Galei Zahal"
  "https://glzwizzlv.bynetcdn.com/glglz_mp3?awCollectionId=misc&awEpisodeId=glglz|Galgalatz"
  "http://www.101smoothjazz.com/101-smoothjazz.m3u|101 Smooth Jazz"
)

TOTAL_STATIONS=${#STATIONS[@]}

# Load current index (default 0)
if [[ -f "$RADIO_INDEX_FILE" ]]; then
  CURRENT_INDEX=$(< "$RADIO_INDEX_FILE")
else
  CURRENT_INDEX=0
fi

# Normalize index to valid range
if ! [[ "$CURRENT_INDEX" =~ ^[0-9]+$ ]] || (( CURRENT_INDEX < 0 || CURRENT_INDEX >= TOTAL_STATIONS )); then
  CURRENT_INDEX=0
fi

save_index() {
  echo "$CURRENT_INDEX" > "$RADIO_INDEX_FILE"
}

# Return "url name" for current station
get_current_station() {
  local station_info="${STATIONS[$CURRENT_INDEX]}"
  local url name
  IFS='|' read -r url name <<< "$station_info"
  echo "$url" "$name"
}

# Is radio playing? (mpv with our socket running)
is_playing() {
  if pgrep -f "mpv.*${MPV_SOCKET}" >/dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

# Start mpv on current station
start_radio() {
  local station_url
  station_url=$(get_current_station | awk '{print $1}')
  # Kill any previous instance using this socket
  pkill -f "mpv.*${MPV_SOCKET}" >/dev/null 2>&1
  nohup mpv --no-video --really-quiet --input-ipc-server="$MPV_SOCKET" "$station_url" \
    >/dev/null 2>&1 &
}

# Stop (but not necessarily quit idle mpv)
stop_radio() {
  pkill -f "mpv.*${MPV_SOCKET}" >/dev/null 2>&1
}

# Full quit – same as stop in this setup
quit_radio() {
  stop_radio
}

# Next station (wrap around)
next_station() {
  CURRENT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_STATIONS ))
  save_index
  if [[ $(is_playing) == "true" ]]; then
    start_radio
  fi
}

# Previous station (wrap around)
prev_station() {
  CURRENT_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL_STATIONS) % TOTAL_STATIONS ))
  save_index
  if [[ $(is_playing) == "true" ]]; then
    start_radio
  fi
}

# Log current station name with timestamp
log_track() {
  local station_name
  station_name=$(get_current_station | cut -d' ' -f2-)
  printf '%s: %s\n' "$(date '+%F %T')" "$station_name" >> "$TRACK_INFO_FILE"
}

# Output for Polybar
update_info() {
  local status icon station_name
  status=$(is_playing)
  station_name=$(get_current_station | cut -d' ' -f2-)

  if [[ "$status" == "true" ]]; then
    icon="$PAUSE_ICON"
  else
    icon="$PLAY_ICON"
  fi

  # Left-click: toggle; Right-click: stop
  # You can add scroll actions for next/prev in polybar config
  echo "%{A1:$0 toggle:}%{A3:$0 stop:}$icon%{A}%{A} $station_name"
}

case "$1" in
  next)
    next_station
    ;;
  prev)
    prev_station
    ;;
  toggle)
    if [[ $(is_playing) == "true" ]]; then
      stop_radio
    else
      start_radio
    fi
    ;;
  stop)
    quit_radio
    ;;
  log)
    log_track
    ;;
esac

update_info

