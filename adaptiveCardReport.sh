set +x

# Types of log format

info() {
echo "\033[1;33m[Info]    \033[0m $1"
}
error() {
echo "\033[1;31m[Error]   \033[0m $1"
}
success() {
echo "\033[1;32m[Success] \033[0m $1"
}

# Takes a list of tags then execute each of them respectively

RunScenarioInSpec(){

  # Remove spaces
  scenarioTags=${1//[[:blank:]]/}

  declare -a tagList
  declare -a TAG_NAMES
  declare -a STATUS
  declare -a STATUS_COLOR
  declare -a TIME

  PASSED='"PASSED"'
  FAILED='"FAILED"'
  ATTENTION='"attention"'
  GOOD='"good"'

  STATUS_PASSED_COUNTER=0
  STATUS_FAILED_COUNTER=0

  IFS=',' #setting , as delimiter and seperate each tag
  read -ra ADDR <<<"$scenarioTags"

  for i in "${ADDR[@]}"; #accessing each tag of tags
  do
    TAG_NAMES+=('"'$i'"') # this is for json
    tagList+=("$i") # this is for iteration
  done

  # Do not forget to unset IFS , otherwise the data will be corrupted in JSON Object etc.
  unset IFS

  # Total second store. This will be converted to the format of min - sec
  totalSec=0

  for i in "${tagList[@]}";
  do
    SECONDS=0 # start timing
    info "$i is preparing to run. Please wait..."
    mvn clean install compile gauge:execute -DspecsDir=specs -Dtags="$i" # execute the scenario according to its tag name

    if [ $? = 0 ]
    	then
        success "The $i execution has been finished successfully..."
        STATUS+=("$PASSED")
        STATUS_COLOR+=("$GOOD")
    	else
   			error "Scenario $i execution failed..."
   			STATUS+=("$FAILED")
   			STATUS_COLOR+=("$ATTENTION")
    fi
    # This is the total seconds. Indicates the time between the begin of the run and end of execution
    totalSec=$((totalSec+SECONDS))
    # This is the time for each separetely.
    # TIME array stores them in order.
    durationParsed="$(($SECONDS / 60))-min---$(($SECONDS % 60))-sec" # get seconds and parse it to minute adn second format
    TIME+=('"'$durationParsed'"')
  done

  # Parsed tota ltime
  totalTime="$(($totalSec / 60))-min---$(($totalSec % 60))-sec"

  # Store al the scores of each scenario.
  # TAG NAME - STATUS - TIME
  declare -a allRows

  # Size of scenarios / tags
  tagSize=${#TAG_NAMES[@]}

  for (( cnt=0; cnt<${tagSize}; cnt++ ))
  do
    tempTagName=${TAG_NAMES[cnt]}
    tempStatus=${STATUS[cnt]}
    tempTime=${TIME[cnt]}
    tempColor=${STATUS_COLOR[cnt]}

    if [[ $tempStatus == "$PASSED" ]]
    then
       ((STATUS_PASSED_COUNTER++))
    elif [[ $tempStatus == "$FAILED" ]]
    then
       ((STATUS_FAILED_COUNTER++))
    else
       echo "WRONG STATUS : None of the condition met"
    fi

    jsonRow='{ "type": "ColumnSet", "spacing": "small", "columns": [ { "type": "Column", "width": "stretch", "items": [ { "type": "TextBlock", "text": '"${tempTagName}"' } ] }, { "type": "Column", "width": "stretch", "items": [ { "type": "TextBlock", "text": '"${tempStatus}"', "color": '"${tempColor}"'  } ] }, { "type": "Column", "width": "stretch", "items": [ { "type": "TextBlock", "text": '"${tempTime}"' } ] } ] }'
    allRows+=("${jsonRow}")
    if [ "${tagSize}" != $((cnt+1)) ]
    then
    allRows+=(',')
    fi
  done

  fullRow='['"${allRows[*]}"']'

  # Adaptive Card JSON
  adaptiveCardReport='{
    "hideOriginalBody": true,
    "type": "AdaptiveCard",
    "padding": "none",
    "body": [
        {
            "type": "ColumnSet",
            "padding": {
                "top": "default",
                "left": "default",
                "bottom": "none",
                "right": "default"
            },
            "columns": [
                {
                    "type": "Column",
                    "verticalContentAlignment": "Center",
                    "items": [
                        {
                            "type": "TextBlock",
                            "verticalContentAlignment": "Center",
                            "horizontalAlignment": "Left",
                            "size": "Large",
                            "text": "<TEXT>",
                            "isSubtle": true
                        }
                    ],
                    "width": "stretch"
                },
                {
                    "type": "Column",
                    "verticalContentAlignment": "Center",
                    "items": [
                        {
                            "verticalContentAlignment": "Center",
                            "type": "Image",
                            "url": "<URL_OF_IMAGE>",
                            "width": "80px",
                            "altText": "Sage Logo"
                        }
                    ],
                    "width": "auto"
                }
            ]
        },
        {
            "separator": true,
            "spacing": "medium",
            "type": "Container",
            "padding": {
                "top": "none",
                "left": "default",
                "bottom": "none",
                "right": "default"
            },
            "items": [
                {
                    "type": "TextBlock",
                    "size": "Medium",
                    "weight": "Bolder",
                    "text": "Test Automation Result"
                },
                {
                    "type": "TextBlock",
                    "text": "Please review the data below. Use See Log button to see in detail",
                    "wrap": true
                }
            ]
        },
        {
            "type": "Container",
            "style": "emphasis",
            "padding": {
                "top": "small",
                "left": "default",
                "bottom": "small",
                "right": "default"
            },
            "items": [
                {
                    "type": "ColumnSet",
                    "columns": [
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "bolder",
                                    "text": "Tags"
                                }
                            ],
                            "width": "stretch"
                        },
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "bolder",
                                    "text": "Status"
                                }
                            ],
                            "width": "stretch"
                        },
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "bolder",
                                    "text": "Time"
                                }
                            ],
                            "width": "stretch"
                        }
                    ]
                }
            ]
        },
        {
            "type": "Container",
            "spacing": "small",
            "padding": {
                "top": "none",
                "left": "default",
                "bottom": "none",
                "right": "default"
            },
            "items": '"${fullRow}"'
        },
        {
            "spacing": "small",
            "type": "Container",
            "style": "emphasis",
            "padding": {
                "top": "small",
                "left": "default",
                "bottom": "small",
                "right": "default"
            },
            "items": [
                {
                    "type": "ColumnSet",
                    "columns": [
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "Bolder",
                                    "text": "Total"
                                }
                            ],
                            "width": "stretch"
                        },
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "Bolder",
                                    "text": "Passed : '"${STATUS_PASSED_COUNTER}"'"
                                },
                                {
                                    "type": "TextBlock",
                                    "weight": "Bolder",
                                    "text": "Failed : '"${STATUS_FAILED_COUNTER}"'"
                                }
                            ],
                            "width": "stretch"
                        },
                        {
                            "type": "Column",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "weight": "Bolder",
                                    "text": "'${totalTime}'"
                                }
                            ],
                            "width": "stretch"
                        }
                    ]
                }
            ]
        }
    ],
    "msteams": {
        "width": "Full"
    },
    "actions": [
        {
            "type": "Action.OpenUrl",
            "title": "See Build History",
            "url": "<URL_TO_NAVIGATE_IF_YOU_WANT>"
        }
    ],
    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
    "version": "1.0"
}'

  # To support Adaptive Cards , use it in connector Card.
  connectorCard='{
   "type":"message",
   "attachments":[
      {
         "contentType":"application/vnd.microsoft.card.adaptive",
         "contentUrl":null,
         "content":
         '${adaptiveCardReport}'
      }
   ]
}'

  curl -d "${connectorCard}" -H "Content-Type: application/json" -X POST <INCOMING_WEBHOOK>


}

scenarioTagsToRun="<TAGS_COMMA_SEPERATED>"
RunScenarioInSpec "${scenarioTagsToRun}"
