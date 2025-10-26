#!/usr/bin/zsh

# Function to handle cleanup on exit
cleanup() {
    rm -f "$fifo"
}

# Trap signals to ensure cleanup
trap cleanup EXIT INT TERM

# Check if input is provided as command line argument
if [[ $# -gt 0 ]]; then
    prompt_var="$*"
    # Create a named pipe (FIFO) for streaming output
    fifo=$(mktemp -u)
    mkfifo "$fifo"

    # Run the command in the background and pipe output to our FIFO
    /home/sment/.lmstudio/bin/lms chat --prompt "$prompt_var" > "$fifo" &

    output=""
    while IFS= read -r line; do
        # Append to our output variable and echo immediately for streaming effect
        output+="$line\n"
        echo "$line"
    done < "$fifo"

    # Clean up
    rm -f "$fifo"
else
    while true; do
        echo -ne '\n(press c to copy to clipboard or q to exit):'
        read -r prompt_var

        case "$prompt_var" in
            q)
                echo "Exiting..."
                break
                ;;
            c)
                if [[ -z "$output" ]]; then
                    echo "No output to copy"
                    continue
                fi
                echo "$output" | pbcopy
                echo "Copied output to clipboard"
                continue
                ;;
            *)
                # Create a named pipe (FIFO) for streaming output
                fifo=$(mktemp -u)
                mkfifo "$fifo"

                # Run the command in the background and pipe output to our FIFO
                /home/sment/.lmstudio/bin/lms chat --prompt "$prompt_var" > "$fifo" &

                output=""
                while IFS= read -r line; do
                    # Append to our output variable and echo immediately for streaming effect
                    output+="$line\n"
                    echo "$line"
                done < "$fifo"

                # Clean up
                rm -f "$fifo"
                ;;
        esac
    done
fi

