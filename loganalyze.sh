# 1. Create the loganalyze script file
cat << 'EOF' > loganalyze
#!/bin/bash

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

ANALYSIS_FILE="analysisData.log"
SUMMARY_FILE="summary.log"

> "$ANALYSIS_FILE"
> "$SUMMARY_FILE"

total_errors=0
max_errors=-1
max_file=""

while IFS= read -r file; do
    if [ -f "$file" ]; then
        count=$(grep -i -c "error" "$file" 2>/dev/null || echo 0)
        result_line="$file: $count error(s)"
        echo "$result_line" | tee -a "$ANALYSIS_FILE"
        
        total_errors=$((total_errors + count))
        if [ "$count" -gt "$max_errors" ]; then
            max_errors=$count
            max_file="$file"
        fi
    fi
done < <(find "$TARGET_DIR" -type f -name "*.log" -mtime -7 2>/dev/null)

if [ -z "$max_file" ]; then
    max_file="None"
    max_errors=0
fi

summary_output="Total errors found: $total_errors\nFile with the most errors: $max_file ($max_errors errors)"
echo -e "\n=== Summary ==="
echo -e "$summary_output"
echo -e "$summary_output" > "$SUMMARY_FILE"
EOF

# 2. Make it executable and move it to a system-wide PATH directory
chmod +x loganalyze
sudo mv loganalyze /usr/local/bin/loganalyze

# 3. Create a manual page configuration so 'whatis' works properly
echo -e ".TH LOGANALYZE 1 \"2026\"\n.SH NAME\nloganalyze - analyzes log files for error counts\n.SH SYNOPSIS\n.B loganalyze\n[DIRECTORY]" > loganalyze.1
sudo mkdir -p /usr/local/share/man/man1
sudo mv loganalyze.1 /usr/local/share/man/man1/
sudo mandb

# 4. Test the commands
echo "--- Testing execution (Current Directory) ---"
loganalyze

echo -e "\n--- Testing 'which' ---"
which loganalyze

echo -e "\n--- Testing 'whatis' ---"
whatis loganalyze# TODO
