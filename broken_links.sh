#
# Find all URLs in a directory and check if they are broken.
#

# Define a function to map a status code to a human readable string.
#
# $1 - The status code.
#
# Returns a human readable string.
#
function status_code_to_string()
{
    case $1 in
        200)
            echo "OK"
            ;;
        201)
            echo "Created"
            ;;
        202)
            echo "Accepted"
            ;;
        203)
            echo "Non-Authoritative Information"
            ;;
        204)
            echo "No Content"
            ;;
        205)
            echo "Reset Content"
            ;;
        206)
            echo "Partial Content"
            ;;
        207) 
            echo "Multi-Status"
            ;;
        208)
            echo "Already Reported"
            ;;
        226)
            echo "IM Used"
            ;;
        301)
            echo "Moved Permanently"
            ;;
        302)
            echo "Found"
            ;;
        303)
            echo "See Other"
            ;;
        304)
            echo "Not Modified"
            ;;
        305)
            echo "Use Proxy"
            ;;
        306)
            echo "Switch Proxy"
            ;;
        307)
            echo "Temporary Redirect"
            ;;
        308)
            echo "Permanent Redirect"
            ;;
        400)
            echo "Bad Request"
            ;;
        401)
            echo "Unauthorized"
            ;;
        403)
            echo "Forbidden"
            ;;
        404)
            echo "Not Found"
            ;;  
        429)
            echo "Too Many Requests"
            ;;
}

# Extract from first argument list of status codes that should be treated as a succesful.
SUCCESS_CODES=$1

echo "Status codes to treat as successful: $SUCCESS_CODES"

# Extract from second argument list of status codes that should be treated as a warning.
WARNING_CODES=$2

echo "Status codes to treat as warnings: $WARNING_CODES"

# Extract from third argument regular expression for URLs that should be ignored.
EXCLUDE_REGEX=$3

echo "Regular expression for URLs to exclude: $EXCLUDE_REGEX"

# Check if the third argument is a directory:
if [ ! -d "$4" ]; then
    # If not, use the current directory:
    DIR="$(pwd)"
else
    # If it is, use the fourth argument:
    DIR="$4"
fi

# Find all files in the directory:
FILES=$(find $DIR -name '*.md' -type f)

# Define list of broken links:
FAILURES=""

# Define list of warnings:
WARNINGS=""

# Loop through all files...
for FILE in $FILES; do
    echo "Checking $FILE for broken links..."
    # Find all URLs in the file:
    URLS=`grep -Po "(?<=\]: )https?://[^ ]*" "$FILE"`
    echo Number of links in $FILE: `echo $URLS | wc -w`
    # Loop through all URLs...
    for URL in $URLS; do
        # Skip in case URL matches the exclude pattern:
        if [ "$EXCLUDE_REGEX" != "none" ]; then
            if [[ "$URL" =~ $EXCLUDE_REGEX ]]; then
                echo "Skipping $URL"
                continue
            fi
        fi
        # Check if the URL is broken:
        STATUS=`curl -I -s -o /dev/null -w "%{http_code}" "$URL"`
        # If the status is 200, 301, or 302, add the URL to the list of broken links:
        if [[ $SUCCESS_CODES != *"$STATUS"* ]]; then
            echo -e "Status code for $URL is $STATUS - $(status_code_to_string $STATUS) \u274C"
            ## Add the URL to the list of broken links if not already there:
            if [[ $FAILURES != *"$URL"* ]]; then
                FAILURES="$FAILURES $URL\n"
            fi
        else 
            if [[ $WARNING_CODES != *"$STATUS"* ]]; then
                echo -e "Status code for $URL is $STATUS - $(status_code_to_string $STATUS) \u2705"
            else
                echo -e "Status code for $URL is $STATUS - $(status_code_to_string $STATUS) \u26A0"
                ## Add the URL to the list of warnings if not already there:
                if [[ $WARNINGS != *"$URL"* ]]; then
                    WARNINGS="$WARNINGS $URL\n"
                fi
            fi
        fi
    done
done

# Assign the list indicating broken links to the `failures` output variable:
echo "::set-output name=failures::$(echo -e $FAILURES)"

# Assign the list indicating warnings to the `warnings` output variable:
echo "::set-output name=warnings::$(echo -e $WARNINGS)"