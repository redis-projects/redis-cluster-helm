#!/bin/bash
 ############################################################
 # Help                                                     #
 ############################################################
 Help()
 {
    # Display Help
    echo "Short script to Create/Add new Namespaces/Projects in OCP & add to the Redis Operator watchlist"
    echo "Pre-reqs: "
    echo "  - Logged into OCP with OC client, have sufficient privileges to Add new projects, add Role & RoleBindings and edit the ConfigMap in the Redis Operators namespace"
    echo "  - The role.yaml and role_binding.yaml are expected in the same DIR as this script. Please copy and update from https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/multi-namespace-redb"
    echo
    echo "NOTE: Error checking is minimal, so you know.. tread carefully ;)"
    echo
    echo "Syntax: scriptTemplate [-g|h|v|V]"
    echo "options:"
    echo "w     Comma Separated List of Namespaces for the Redis Operator to Watch"
    echo "n     Namespace which Operator is installed. Default is 'Redis'"
    echo "h     Print help..!"
    echo
 }

 ############################################################
 ############################################################
 # Main program                                             #
 ############################################################
 ############################################################
 ############################################################
 # Process the input options. Add options as needed.        #
 ############################################################
 # Get the options

# Define Bash Arguments
while getopts ":hw:n:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      n) # Operator Namespace
          opt_os=$OPTARG;;
      w) # Namespaces to Watch
          watch_ns=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1;;
   esac
done

# Default to Redis namespace if null
if [ -z "$opt_os" ]
then
      echo "\$opt_os is NULL defaulting to Redis"
      opt_os='Redis'
fi

# Add option to bail out
read -p "Are you sure you want to add these namespaces: '$watch_ns' to the Operator watchlist in '$opt_os'? 'y' to continue or 'n' to bail! " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "You have decided to bail.. see ya soon! "
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

# Create Namespace & Apply Role/RoleBinding
function roleProcessingFunction() {
  echo "Executing $1 && $2 what about $opt_os"

  # Test if Openshift Project Exists
  oc get "project/"$1 > /dev/null 2>&1

  if [ "$?" != "0" ]; then
      echo "Creating project :: $1"
      oc new-project $1
  fi

  # Apply the Roles & RoleBinding against the namespace
  echo "Applying Role to '$1'"
  oc apply -f role.yaml -n $1

  echo "Applying Role to '$1'"
  oc apply -f role_binding.yaml -n $1

}

# Check existing watched namespaces are not added a second time
dedupeNSList() {
  if [ -z "$NAMESPACES" ]
  then
        NAMESPACES=$NS_TO_ADD
  else
    # Iterate over NS list and dedupe against existing list
    IFS=',' read -ra NS <<< "$NS_TO_ADD"
    for j in "${NS[@]}"; do
      if [[ ! (",$NAMESPACES," = *",$j,"*) ]]
        then
          NAMESPACES="${NAMESPACES},$j"
      fi
    done
  fi
}

# Add newly namespaces to Redis Operator Watchlist
function addNewNamespacesToOperatorWatchList() {
  echo "Adding the following NEW namespaces to the Operator watch list: $1"

  #Get existing Namespace watch list
  NAMESPACES=$(oc get configmap/operator-environment-config -n redis -o jsonpath="{.data['REDB_NAMESPACES']}")

  # Get a list of the current namespaces watched & aggregate with new list
  echo "Current namespaces watched: '$NAMESPACES'"
  dedupeNSList
  echo "New redis watched namespaces list:  '$NAMESPACES'"

  # Current watch list already contains all Namespaces
  if [ -z "$NAMESPACES" ]
    then
      echo "Namespaces to update Redis Operator watchlist has resolved to null, nothing to update"
      exit;
  fi

  # Escape all the JSON madness using ASCII tags
  NAMESPACES_FINAL="\x27{\x22data\x22:{\x22REDB_NAMESPACES\x22:\x22${NAMESPACES}\x22}}\x27"
  echo -e "Final Patch Command: ${NAMESPACES_FINAL}"

  # Patch Openshift to watch the new list
  echo "Patching the Redis Operator in '$2' namespace to watch '$NAMESPACES'"
  oc patch configmap/operator-environment-config \
    -n redis \
    --type merge \
    -p "{\"data\":{\"REDB_NAMESPACES\":\"${NAMESPACES}\"}}"

  echo "Redis Operator now watching namespaces :: $(oc get configmap/operator-environment-config -n redis -o jsonpath="{.data['REDB_NAMESPACES']}")"
}

# Update List of Namespaces to add
function updateSuccessfullyUpdatedNS() {
    if [ -z "$NS_TO_ADD" ]
    then
          NS_TO_ADD=$1
    else
          NS_TO_ADD="${NS_TO_ADD},$1"
    fi
}

# Process Each of the requested namespace
IFS=',' read -ra ADDR <<< "$watch_ns"
for i in "${ADDR[@]}"; do
  printf "Processing $i and adding to $opt_os \n"
  roleProcessingFunction $i $opt_os

  if [ $? -eq 0 ]; then
     echo "Successfully created/updated namespace $i with additional Role & RoleBinding"
     updateSuccessfullyUpdatedNS $i
  else
     echo "Unsuccessfully created/updated namespace $i with additional Role & RoleBinding, please check logs & permissions"
  fi

done

# Finally add successfully updated namespaces to Redis Operator Watchlist
addNewNamespacesToOperatorWatchList $NS_TO_ADD
