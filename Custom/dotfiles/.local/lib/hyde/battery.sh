#!/usr/bin/env bash
usage() {
    cat << USAGE
Usage: battery.sh [OPTIONS]

Options:
  icon          Display the battery icon
  percentage    Display the battery percentage
  int           Display the battery percentage as an integer
  status        Display the battery status (Charging, Discharging, etc.)
  status-icon   Display an icon representing the battery status
  -h, --help    Display this help message
USAGE
}
if [[ $1 == "-h" || $1 == "--help" ]]; then
    usage
    exit 0
fi

average_capacity=""
get_capacity() {
    [[ -n "$average_capacity" ]] && return 0
    local caps=()
    readarray -t caps < <(inxi -B -c 0 2>/dev/null | grep -oP 'charge:.*?\b\K[0-9]+(?=(\.[0-9]+)?%)')
    local count=${#caps[@]}
    if (( count == 0 )); then
        exit 0
    fi
    local total=0
    for c in "${caps[@]}"; do
        total=$((total + c))
    done
    average_capacity=$((total / count))
}

battery_status=""
get_status() {
    [[ -n "$battery_status" ]] && return 0
    local raw_status
    raw_status=$(inxi -Bx -c 0 2>/dev/null | grep -oiP 'status:\s*\K(charging|discharging|not charging|full|unknown|\w+)' | head -n 1)
    case "${raw_status,,}" in
        "charging") battery_status="Charging" ;;
        "not charging") battery_status="Not Charging" ;;
        "discharging") battery_status="Discharging" ;;
        "full") battery_status="Full" ;;
        *) battery_status="${raw_status^}" ;;
    esac
}

charging_icons=("󰂆 " "󰂇 " "󰂈 " "󰂉 " "󰂊 " "󰂋 " "󰂋 " "󰂋 " "󰂋 " "󰂋 " "󰂅 ")
discharging_icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
status_icons=("" "X" "󰂇")
formats=("$@")

output_format() {
    case "$1" in
        icon)
            get_capacity
            get_status
            local index=$((average_capacity / 10))
            if [[ $battery_status == "Charging" ]]; then
                echo -n "${charging_icons[$index]} "
            else
                echo -n "${discharging_icons[$index]} "
            fi
            ;;
        percentage)
            get_capacity
            echo -n "$average_capacity% "
            ;;
        int)
            get_capacity
            echo -n "$average_capacity "
            ;;
        status)
            get_status
            echo -n "$battery_status "
            ;;
        status-icon)
            get_status
            case "$battery_status" in
                "Charging")
                    echo -n "${status_icons[0]} "
                    ;;
                "Not Charging")
                    echo -n "${status_icons[1]} "
                    ;;
                *) echo -n "${status_icons[2]} " ;;
            esac
            ;;
        *)
            echo "Invalid format option: $1. Use 'icon', 'percentage', 'int', 'status', or 'status-icon'."
            exit 1
            ;;
    esac
}

if [ ${#formats[@]} -eq 0 ]; then
    output_format "icon"
else
    for format in "${formats[@]}"; do
        output_format "$format"
    done
    echo
fi
