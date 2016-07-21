#!/bin/bash
SYSTEM_JVM=/usr/java/jdk1.7.0_71/bin/java_jel

GREP=`which grep`
SED=`which sed`

JELASTIC_GC_AGENT="jelastic-gc-agent.jar"

java_params="$@" ;
# echo $java_params;

generateOptimalSettings(){
    # clean_env;
    GC_LIMMIT=8000;
    [ -z "$XMS" ] && { XMS=42M; }
    [ -z "$XMN" ] && { XMN=40M; }
    local memory_total=`free -m | $GREP Mem | awk '{print $2}'`;
    [ -z "$XMX" ] && {
        let XMX=memory_total-55;
        XMX="${XMX}M";
    }
    [ -z "$GC" ] && {
       [ "$memory_total" -ge "$GC_LIMMIT" ] && GC="-XX:+UseG1GC" || GC="-XX:+UseParNewGC";
    }
}

updateMemoryConfig(){
    local cfgName=$3
    count=`$GREP -c -e $2 <<< $cfgName`;
    if [ "$count" -eq 1 ]
    then
        cfgName=$($SED -e "/^/s/$2/$1 /"  <<< $cfgName) ;
    else
        cfgName=$($SED -re "/^/s//$1 /" <<< $cfgName);
    fi
    echo $cfgName
}

setMemoryConfig(){
    local cfgName=$3
    count=`$GREP -c -e $2 <<< $cfgName`;
    if [ "$count" -ne 1 ] ; then
        cfgName=$($SED -re "/^/s//$1 /" <<< $cfgName);
    fi
    echo $cfgName
}

updateOptions(){
    local configOpt=$1
    [ ! -z "$XMX" ] && configOpt=$(updateMemoryConfig "-Xmx$XMX" "-Xmx[[:digit:]]\{1,\}[MGkKmg[:space:]]" "$configOpt")
    [ ! -z "$XMS" ] && configOpt=$(updateMemoryConfig "-Xms$XMS" "-Xms[[:digit:]]\{1,\}[MGkKmg[:space:]]" "$configOpt")
    [ ! -z "$XMN" ] && configOpt=$(updateMemoryConfig "-Xmn$XMN" "-Xmn[[:digit:]]\{1,\}[MGkKmg[:space:]]" "$configOpt")
    configOpt=$(setMemoryConfig "-Xminf0.1" "-Xminf[[:digit:].]\{1,\}" "$configOpt")
    configOpt=$(setMemoryConfig "-Xmaxf0.1" "-Xmaxf[[:digit:].]\{1,\}" "$configOpt")
    configOpt=$(setMemoryConfig "-XX:MaxPermSize=256m" "-XX:MaxPermSize=[[:digit:]]\{1,\}[MGkKmg[:space:]]" "$configOpt")
    configOpt=$(setMemoryConfig "-XX:+UseCompressedOops" "-XX:UseCompressedOops" "$configOpt")
    #configOpt=$(setMemoryConfig "${JELASTIC_GC_AGENT}" "-XX:-UseAdaptiveSizePolicy" "$configOpt")
    # if ! $GREP -q ${JELASTIC_GC_AGENT} <<< $configOpt; then
    #            configOpt="-javaagent:/opt/tomcat/tmp/jelastic-gc-agent.jar "$configOpt
    # fi
    if $GREP -q ${JELASTIC_GC_AGENT} <<< $configOpt; then
        configOpt=$(setMemoryConfig "-XX:-UseAdaptiveSizePolicy" "UseAdaptiveSizePolicy" "$configOpt")
        # if ! $GREP -q 'UseAdaptiveSizePolicy' <<< $configOpt ; then
        #     configOpt="-XX:-UseAdaptiveSizePolicy "$configOpt
        # fi
    fi
    configOpt="$GC "$configOpt
    # sed -e '/^JAVA_OPTS/s/ \{1,\}/ /g'
    echo "$configOpt"
}


setOpts(){
    generateOptimalSettings;
    java_params=$(updateOptions "$java_params");
    if [ ! -z "$JAVA_OPTS" ]  ; then
        JAVA_OPTS=$(updateOptions "$JAVA_OPTS");
        export "JAVA_OPTS=$JAVA_OPTS"
    fi
}

setOpts
#export JAVA_HOME=${SYSTEM_VM%/bin/java}
# echo "JAVA_OPTS: $JAVA_OPTS" >> /log.log
# JAVA_OPTS=$($SED -e "/^/s/-Xmn[[:digit:]]\{1,\}[MGkKmg[:space:]]/-Xmn$XMN/" -e 's/ \{1,\}/ /g' <<< $JAVA_OPTS) ;
# export JAVA_OPTS="$JAVA_OPTS"
# echo "JAVA_OPTS 2: $JAVA_OPTS" >> /log.log
 
# echo "${java_params}"
# echo $JAVA_OPTS
# env
exec ${SYSTEM_JVM} $java_params
