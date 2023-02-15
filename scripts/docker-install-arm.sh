#!/bin/bash
MW_LOG_PATHS=""

if [[ $(which docker) && $(docker --version) ]]; then
  echo -e ""
else
  echo -e "\nSeems like docker is not already installed on the system"
  echo -e "\nPlease install docker first, This link might be helpful : https://docs.docker.com/engine/install/\n"
  exit 1
fi

echo -e "\nThe host agent will monitor all '.log' files inside your /var/log directory recursively [/var/log/**/*.log]"
while true; do
    read -p "`echo -e '\nDo you want to monitor any more directories for logs ? \n[C-continue to quick install | A-advanced log path setup]\n[C|A] : '`" yn
    case $yn in
        [Aa]* )
          MW_LOG_PATH_DIR=""
          
          while true; do
            read -p "    Enter list of comma seperated paths that you want to monitor [ Ex. => /home/test, /etc/test2 | S - skip and continue ] : " MW_LOG_PATH_DIR
            export MW_LOG_PATH_DIR
            if [[ $MW_LOG_PATH_DIR =~ ^/|(/[\w-]+)+(,/|(/[\w-]+)+)*$ ]]
            then 
              break
            else
              echo $MW_LOG_PATH_DIR
              echo "Invalid file path, try again ..."
            fi
          done

          MW_LOG_PATH_COMPLETE=""
          MW_LOG_PATHS_BINDING=""

          MW_LOG_PATH_DIR_ARRAY=($(echo $MW_LOG_PATH_DIR | tr "," "\n"))

          for i in "${MW_LOG_PATH_DIR_ARRAY[@]}"
          do
            MW_LOG_PATHS_BINDING=$MW_LOG_PATHS_BINDING" -v $i:$i"
            if [ "${MW_LOG_PATH_COMPLETE}" = "" ]; then
              MW_LOG_PATH_COMPLETE="$MW_LOG_PATH_COMPLETE$i/**/*.*"
            else
              MW_LOG_PATH_COMPLETE="$MW_LOG_PATH_COMPLETE,$i/**/*.*"
            fi
          done

          export MW_LOG_PATH_COMPLETE

          MW_LOG_PATHS=$MW_LOG_PATH_COMPLETE
          export MW_LOG_PATHS
          echo -e "\n------------------------------------------------"
          echo -e "\nNow, our agent will also monitor these paths : "$MW_LOG_PATH_COMPLETE
          echo -e "\n------------------------------------------------\n"
          sleep 4
          break;;
        [Cc]* ) 
          echo -e "\n----------------------------------------------------------\n\nOkay, Continuing installation ....\n\n----------------------------------------------------------\n"
          break;;
        * ) 
          echo -e "\nPlease answer with c or a."
          continue;;
    esac
done

docker pull ghcr.io/middleware-labs/agent-host-go-arm:master
dockerrun="docker run -d \
--name mw-agent-${MW_API_KEY:0:5} \
--pid host \
--restart always \
-e MW_API_KEY=$MW_API_KEY \
-e MW_LOG_PATHS=$MW_LOG_PATHS \
-e TARGET=$TARGET \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /var/log:/var/log \
-v /tmp:/tmp \
$MW_LOG_PATHS_BINDING \
--privileged \
--network=host ghcr.io/middleware-labs/agent-host-go-arm:master api-server start"

export dockerrun
eval " $dockerrun"