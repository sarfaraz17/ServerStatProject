#!/bin/bash
# -----------------------------------------------------------
# Script: server-stats.sh
# Description: Gathers and displays basic Linux server
#              performance and system statistics.
# Usage: Run with 'bash server-stats.sh' or './server-stats.sh'
# -----------------------------------------------------------

# Function to print a stylized header
print_header() {
    echo -e "\n========================================================"
    echo -e " \033[1;36mSERVER PERFORMANCE REPORT: $(date)\033[0m"
    echo -e "========================================================"
}

# Function to print a section title
print_section_title() {
    echo -e "\n--- \033[1;32m$1\033[0m -------------------------------------------------"
}

# --- SYSTEM INFORMATION (Stretch Goal) ------------------------
print_section_title "System Information"

echo -e "OS Version: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')"
echo -e "Kernel:     $(uname -r)"
echo -e "Uptime:     $(uptime -p)"
echo -e "Load Avg:   $(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')"

# --- CPU USAGE ANALYSIS ---------------------------------------
print_section_title "CPU Usage"

# Get current CPU usage (user + system time, excluding idle and waiting)
# Uses vmstat for quick, reliable, and standardized reading.
# We run it for 2 cycles with 1-second delay and take the average of the second line.
CPU_IDLE=$(vmstat 1 2 | tail -1 | awk '{print $15}')
CPU_USAGE=$((100 - CPU_IDLE))

echo -e "Total CPU Usage: \033[1;33m${CPU_USAGE}%\033[0m"

# --- MEMORY USAGE ANALYSIS ------------------------------------
print_section_title "Memory Usage (MB)"

# Get memory stats using 'free -m'
# Total, Used, Free in MB
MEMORY_TOTAL=$(free -m | grep Mem | awk '{print $2}')
MEMORY_USED=$(free -m | grep Mem | awk '{print $3}')
MEMORY_FREE=$(free -m | grep Mem | awk '{print $4}')

# Calculate percentage usage
if [ "$MEMORY_TOTAL" -gt 0 ]; then
    MEMORY_PERCENT=$(echo "scale=2; ($MEMORY_USED / $MEMORY_TOTAL) * 100" | bc)
else
    MEMORY_PERCENT="0.00"
fi

echo "Total: ${MEMORY_TOTAL} MB"
echo "Used:  ${MEMORY_USED} MB (\033[1;33m${MEMORY_PERCENT}%\033[0m)"
echo "Free:  ${MEMORY_FREE} MB"

# --- DISK USAGE ANALYSIS --------------------------------------
print_section_title "Disk Usage (Excluding temporary files)"

# Uses 'df -h' to get human-readable disk usage.
# Excludes temporary and device-related file systems for cleaner output.
df -h --exclude-type=tmpfs --exclude-type=devtmpfs

# --- TOP PROCESSES BY CPU -------------------------------------
print_section_title "Top 5 Processes by CPU Usage"

# Uses 'ps aux' to list all processes, sorts numerically by 3rd column (%CPU),
# reverses the sort, and takes the top 6 lines (excluding the header).
ps aux --sort=-%cpu | head -n 6

# --- TOP PROCESSES BY MEMORY ----------------------------------
print_section_title "Top 5 Processes by Memory Usage"

# Uses 'ps aux' to list all processes, sorts numerically by 4th column (%MEM),
# reverses the sort, and takes the top 6 lines (excluding the header).
ps aux --sort=-%mem | head -n 6

# --- LOGIN & SECURITY (Stretch Goal) --------------------------
print_section_title "Login and Security Stats"

echo -e "Currently Logged In Users:"
who

# Count failed login attempts (requires appropriate logging and permissions)
# Using a common log file path, but might need adjustment based on OS/distro.
if [ -f /var/log/auth.log ]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
    echo -e "Failed Login Attempts (auth.log): \033[1;31m${FAILED_LOGINS}\033[0m"
elif [ -f /var/log/secure ]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/secure | wc -l)
    echo -e "Failed Login Attempts (secure): \033[1;31m${FAILED_LOGINS}\033[0m"
else
    echo "Failed Login Attempts: Log file not found (/var/log/auth.log or /var/log/secure)"
fi

echo -e "\n========================================================\n"

exit 0