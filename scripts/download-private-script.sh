# linode/download-private-script.sh by vincentcr
# id: 3039
# description: functions to download or execute a private script from an api key and a script label (tested on ubuntu 11.04 but should work on any distro with python >= 2.6 and curl installed).
# defined fields: 
# images: ['linode/ubuntu10.04lts32bit', 'linode/ubuntu10.04lts', 'linode/ubuntu11.0432bit', 'linode/ubuntu11.04']
# stats: Used By: 0 + AllTime: 0
#!/bin/bash 

# functions to download or execute a private script
# from an api key and a script label.
# tested on ubuntu 11.04 but should work  
# on any distro with python >= 2.6 and curl installed.


function exe_private_script {
    local api_key=$1
    local label=$2

    if [ -z "$api_key" ] ; then
        echo "api key is required"
        return 1
    elif [ -z "$label" ] ; then
        echo "script label is required"
        return 1
    fi

    shift 2
    local args=$@
    local dst=$(mktemp)

    download_private_script $api_key $label $dst
    ret=$?
    if [ $ret == 0 ] ; then
        eval "$dst $args"
        ret=$?
    fi
    if [ -f $dst ] ; then
        rm $dst
    fi
    return $ret
}

function download_private_script {
    local api_key=$1
    local label=$2
    local dst=$3    

    if [ -z "$api_key" ] ; then
        echo "api key is required"
        return 1
    elif [ -z "$label" ] ; then
        echo "script label is required"
        return 1
    elif [ -z "$dst" ] ; then
        echo "script destination is required"
        return 1
    fi

    local json=$(mktemp)

    _dps_api_query $api_key stackscript.list $json
    _dps_extract_script $json $label $dst
    ret=$?
    rm $json
    return $ret
}

function _dps_api_query {
    local key=$1
    local args=$2
    local out=$3
    echo key= $key args= $args out= $out

    local url="https://api.linode.com/?api_key=$key&api_action=$args"
    
    echo $out
    curl $url > $out
    #cat $out | python -mjson.tool
}

function _dps_extract_script {
    local json=$1
    local label=$2
    local dst=$3
    local script=$(mktemp)

    #simple python script to query the json
    cat <<END > $script

#!/usr/bin/env python

import json, sys

with open('$json') as f:
    txt = f.read()

data = json.loads(txt)

scripts = data['DATA']

for script in scripts:
    if script['LABEL'] == '$label':
        content=script['SCRIPT']
        
        with open('$dst', 'w') as f:
            f.write(content)
            f.write('\n')
            sys.exit(0)

raise Exception("could not find script '$label' in:\n" + data)

END

    python $script
    ret=$?
    rm $script
    if [ -f $dst ] ; then
        chmod a+x $dst
    fi

    return $ret
}