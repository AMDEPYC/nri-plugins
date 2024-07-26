# get lastCPU used for all running containers in the system that is not the kube-system or calico namespace
allNonKubePods=`crictl pods | grep -vF "kube-system" | grep -v "calico" | grep -v "operator" | tr -d "POD" | cut -d ' ' -f1`

for podID in ${allNonKubePods}; do
        # get the containerID of a pod
        containerID=`crictl ps -p ${podID} -q`
        if [ -n "$containerID" ]; then
          #get the PID of the container
          pPID=`crictl inspect --output go-template --template '{{.info.pid}}' ${containerID}`

          lsCPUAssigned=`cat /proc/${pPID}/stat | cut -d ' ' -f 39`

          #get all the child process ID
          lsChildPID=`pgrep -P ${pPID}`
          if [ -n "$lsChildPID" ]; then
            for childPID in ${lsChildPID} ; do
                # get the last used CPU
                lastUsedCPU=`cat /proc/${childPID}/stat | cut -d ' ' -f 39`
                lsCPUAssigned=" $lsCPUAssigned $lastUsedCPU"
            done
          fi
          echo "PODId=${podID}  containerID=${containerID} cpulastUsed=${lsCPUAssigned}"
        fi
done

# get the topology of the system by iterating through the sys/devices/system/cpu directory
# get the numa nodes
lsNuma=`ls /sys/devices/system/node/ | grep node[0-9]`
index=0
for numa in ${lsNuma}; do
        echo "numa ${numa}"
        # get list of cpus in the numa node
        lsCPUs=`ls /sys/devices/system/node/${numa} | grep 'cpu[0-9]\+'`

        for cpus in ${lsCPUs}; do
          # get the L3 group id of a cpu
          l3GroupID=`cat /sys/devices/system/node/${numa}/${cpus}/cache/index3/id`
          ccdIndex=`expr ${l3GroupID}`
          if [ -z "${cpuGrouping[${ccdIndex}]}" ]; then
                  # initialize if this is start of a new L3 grouping and the variable is empty or null
                  cpuGrouping[${ccdIndex}]="${cpus}"
          else
                cpuGrouping[${ccdIndex}]="${cpuGrouping[${ccdIndex}]} ${cpus}"
          fi
        done

        for ((i=$index; i<${#cpuGrouping[@]}; ++i)); do
                echo "L3(CCD)Id=$i ${cpuGrouping[i]}"
                index=$i
        done
        index=$index+1

done

