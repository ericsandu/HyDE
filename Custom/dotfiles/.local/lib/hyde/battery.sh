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

inxi_output=$(inxi -Bx -c 0 2>/dev/null)
readarray -t capacities < <(echo "$inxi_output" | grep -oP 'charge:[^(]*\(\K[0-9]+(?=%\))')
battery_count=${#capacities[@]}

if ((battery_count == 0)); then
    exit 0
fi

total_capacity=0
for cap in "${capacities[@]}"; do
    total_capacity=$((total_capacity + cap))
done
average_capacity=$((total_capacity / battery_count))
index=$((average_capacity / 10))
charging_icons=("󰂆 " "󰂇 " "󰂈 " "󰂉 " "󰂊 " "󰂋 " "󰂋 " "󰂋 " "󰂋 " "󰂋 " "󰂅 ")
discharging_icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
status_icons=("" "X" "󰂇")
raw_status=$(echo "$inxi_output" | grep -oP 'status:\s*\K\w+' | head -n 1)
battery_status="${raw_status^}"
formats=("$@")
output_format() {
    case "$1" in
        icon)
            if
                [[ $battery_status == "Charging" ]]
            then
                echo -n "${charging_icons[$index]} "
            else
                echo -n "${discharging_icons[$index]} "
            fi
            ;;
        percentage)
            echo -n "$average_capacity% "
            ;;
        int)
            echo -n "$average_capacity "
            ;;
        status)
            echo -n "$battery_status "
            ;;
        status-icon)
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
