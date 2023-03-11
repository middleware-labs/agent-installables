#!/bin/sh

# recording agent installation attempt
curl -s --location --request POST https://app.middleware.io/api/v1/agent/tracking/$MW_API_KEY \
--header 'Content-Type: application/json' \
--data-raw '{
    "status": "tried",
    "metadata": {
        "script": "kubernetes-auto-instrument",
        "status": "ok",
        "message": "agent installed"
    }
}' > /dev/null

# Home for local configs
MW_KUBE_AGENT_HOME_GO=/usr/local/bin/mw-agent-kube-go
export MW_KUBE_AGENT_HOME_GO

# Helm chart version
MW_DEFAULT_HELM_VERSION=0.2.46
if [ "${MW_HELM_VERSION}" = "" ]; then 
  MW_HELM_VERSION=$MW_DEFAULT_HELM_VERSION
  export MW_HELM_VERSION
fi

# Target Namespace - For Middleware Agent Workloads
MW_DEFAULT_NAMESPACE=mw-vision
export MW_DEFAULT_NAMESPACE

if [ "${MW_NAMESPACE}" = "" ]; then 
  MW_NAMESPACE=$MW_DEFAULT_NAMESPACE
  export MW_NAMESPACE
fi

# Default rollout time rule
# MW_DEFAULT_ROLLOUT_RESTART_RULE=0 8 * * *
# export MW_DEFAULT_ROLLOUT_RESTART_RULE

# if [ "${MW_ROLLOUT_RESTART_RULE}" = "" ]; then 
#   MW_ROLLOUT_RESTART_RULE=$MW_DEFAULT_ROLLOUT_RESTART_RULE
#   export MW_ROLLOUT_RESTART_RULE
# fi

# Fetching cluster name
CURRENT_CONTEXT="$(kubectl config current-context)"
MW_KUBE_CLUSTER_NAME="$(kubectl config view -o jsonpath="{.contexts[?(@.name == '"$CURRENT_CONTEXT"')].context.cluster}")"
export MW_KUBE_CLUSTER_NAME

echo -e "\nSetting up Middleware Agent ...\n\n\tcluster : $MW_KUBE_CLUSTER_NAME \n\tcontext : $CURRENT_CONTEXT\n"

# MW_LOG_PATHS=""

# echo -e "\nThe host agent will monitor all '.log' files inside your/var/log/pods directory [/var/log/pods/*/*/*.log]"
# while true; do
#     read -p "Do you want to monitor any more directories for logs (from Kubernetes node filesystem) ? [Y|n] : " yn
#     case $yn in
#         [Yy]* )
#           MW_LOG_PATH_DIR=""
          
#           while true; do
#             read -p "    Enter list of comma seperated paths that you want to monitor [ Ex. => /home/test, /etc/test2] : " MW_LOG_PATH_DIR
#             export MW_LOG_PATH_DIR
#             if [[ $MW_LOG_PATH_DIR =~ ^/|(/[\w-]+)+(,/|(/[\w-]+)+)*$ ]]
#             then 
#               break
#             else
#               echo $MW_LOG_PATH_DIR
#               echo "Invalid file path, try again ..."
#             fi
#           done

#           MW_LOG_PATH_COMPLETE=""

#           MW_LOG_PATH_DIR_ARRAY=($(echo $MW_LOG_PATH_DIR | tr "," "\n"))

#           for i in "${MW_LOG_PATH_DIR_ARRAY[@]}"
#           do
#             if [ "${MW_LOG_PATH_COMPLETE}" = "" ]; then
#               MW_LOG_PATH_COMPLETE="$MW_LOG_PATH_COMPLETE$i/**/*.*"
#             else
#               MW_LOG_PATH_COMPLETE="$MW_LOG_PATH_COMPLETE,$i/**/*.*"
#             fi
#           done

#           export MW_LOG_PATH_COMPLETE

#           MW_LOG_PATHS=$MW_LOG_PATH_COMPLETE
#           export MW_LOG_PATHS
#           echo -e "\n------------------------------------------------"
#           echo -e "\nNow, our agent will also monitor these paths : "$MW_LOG_PATH_COMPLETE
#           echo -e "\n------------------------------------------------\n"
#           sleep 4
#           break;;
#         [Nn]* ) 
#           echo -e "\n----------------------------------------------------------\n\nOkay, Continuing installation ....\n\n----------------------------------------------------------\n"
#           break;;
#         * ) 
#           echo -e "\nPlease answer y or n."
#           continue;;
#     esac
# done

# sudo su << EOSUDO
# mkdir -p $MW_KUBE_AGENT_HOME_GO
# touch $MW_KUBE_AGENT_HOME_GO/agent.yaml
# wget -q -O $MW_KUBE_AGENT_HOME_GO/agent.yaml https://install.middleware.io/scripts/mw-kube-agent-auto-instrument.yaml
# EOSUDO

# if [ -z "${MW_KUBECONFIG}" ]; then
#     sed -e 's|MW_KUBE_CLUSTER_NAME_VALUE|'${MW_KUBE_CLUSTER_NAME}'|g' -e 's|MW_ROLLOUT_RESTART_RULE|'${MW_ROLLOUT_RESTART_RULE}'|g' -e 's|MW_LOG_PATHS|'$MW_LOG_PATHS'|g' -e 's|MW_DOCKER_ENDPOINT_VALUE|'${MW_DOCKER_ENDPOINT}'|g' -e 's|MW_API_KEY_VALUE|'${MW_API_KEY}'|g' -e 's|TARGET_VALUE|'${TARGET}'|g' -e 's|NAMESPACE_VALUE|'${MW_NAMESPACE}'|g' $MW_KUBE_AGENT_HOME_GO/agent.yaml | sudo tee $MW_KUBE_AGENT_HOME_GO/agent.yaml > /dev/null
#     kubectl apply --kubeconfig=${MW_KUBECONFIG}  -f $MW_KUBE_AGENT_HOME_GO/agent.yaml
#     kubectl --kubeconfig=${MW_KUBECONFIG} -n ${MW_NAMESPACE} rollout restart daemonset/mw-kube-agent
# else
    
    # sed -e 's|MW_KUBE_CLUSTER_NAME_VALUE|'${MW_KUBE_CLUSTER_NAME}'|g' -e 's|MW_ROLLOUT_RESTART_RULE|'MW_ROLLOUT_RESTART_RULE'|g' -e 's|MW_LOG_PATHS|'$MW_LOG_PATHS'|g' -e 's|MW_DOCKER_ENDPOINT_VALUE|'${MW_DOCKER_ENDPOINT}'|g' -e 's|MW_API_KEY_VALUE|'${MW_API_KEY}'|g' -e 's|TARGET_VALUE|'${TARGET}'|g' -e 's|NAMESPACE_VALUE|'${MW_NAMESPACE}'|g' $MW_KUBE_AGENT_HOME_GO/agent.yaml | sudo tee $MW_KUBE_AGENT_HOME_GO/agent.yaml > /dev/null
    # kubectl apply -f $MW_KUBE_AGENT_HOME_GO/agent.yaml

    # kubectl -n ${MW_NAMESPACE} rollout restart daemonset/mw-kube-agent

    helm repo add middleware-vision https://helm.middleware.io

    if helm list --namespace default --short | grep -q "mw-vision-suite"; then 
      echo ""
    else 
      helm uninstall mw-vision-suite -n ${MW_NAMESPACE}; 
      kubectl delete configmap mw-configmap -n ${MW_NAMESPACE}
    fi

    if kubectl get configmap mw-configmap --namespace ${MW_NAMESPACE} >/dev/null 2>&1; then
      echo "Good ! We already have mw-configmap !"
    else
      kubectl create configmap mw-configmap \
      -n ${MW_NAMESPACE} \
      --from-literal=MW_API_KEY=${MW_API_KEY} \
      --from-literal=TARGET=${TARGET} \
      --from-literal=MW_KUBE_CLUSTER_NAME=${MW_KUBE_CLUSTER_NAME} \
      --from-literal=MW_ROLLOUT_RESTART_RULE=${MW_ROLLOUT_RESTART_RULE}
    fi

    helm install \
    -n ${MW_NAMESPACE} \
    --create-namespace \
    mw-vision-suite middleware-labs/middleware-vision --version ${MW_HELM_VERSION}

# fi
