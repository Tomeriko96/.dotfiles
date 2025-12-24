#!/usr/bin/env bash
# MPV-based internet radio controller for Polybar

RADIO_INDEX_FILE="/tmp/current_radio_index"
MPV_SOCKET="/tmp/mpv-radio-socket"

# Icons (require Nerd Fonts or similar)
PLAY_ICON=""
PAUSE_ICON=""

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
  local idx="$CURRENT_INDEX"
  echo "$idx" > "$RADIO_INDEX_FILE"
}

get_current_station() {
  local idx url name station_info
  idx="$CURRENT_INDEX"
  station_info="${STATIONS[$idx]}"
  IFS='|' read -r url name <<< "$station_info"
  echo "$url" "$name"
}

is_playing() {
  local socket="$MPV_SOCKET"
  pgrep -f "mpv.*${socket}" >/dev/null 2>&1 && echo "true" || echo "false"
}

start_radio() {
  local station_url socket
  station_url=$(get_current_station | awk '{print $1}')
  socket="$MPV_SOCKET"
  pkill -f "mpv.*${socket}" >/dev/null 2>&1
  nohup mpv --no-video --really-quiet --input-ipc-server="$socket" "$station_url" \
    >/dev/null 2>&1 &
  sleep 0.5
  if ! pgrep -f "mpv.*${socket}" >/dev/null 2>&1; then
    echo "Error: Failed to start MPV for $station_url" >&2
  fi
}

stop_radio() {
  local socket="$MPV_SOCKET"
  pkill -f "mpv.*${socket}" >/dev/null 2>&1
}

next_station() {
  local idx total
  idx="$CURRENT_INDEX"
  total="$TOTAL_STATIONS"
  CURRENT_INDEX=$(( (idx + 1) % total ))
  save_index
  if [[ $(is_playing) == "true" ]]; then
    start_radio
  fi
}

update_info() {
  local status icon station_name display_text track_info
  status=$(is_playing)
  station_name=$(get_current_station | cut -d' ' -f2-)
  icon="$PLAY_ICON"
  display_text="$station_name"
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
  toggle)
    if [[ $(is_playing) == "true" ]]; then
      stop_radio
    else
      start_radio
    fi
    ;;
  stop)
    stop_radio
    ;;
esac

update_info

