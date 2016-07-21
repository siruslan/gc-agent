#!/bin/bash
echo > /path/to/scripts/date;
date +%Y-%m-%d-%H%M > /path/to/scripts/date;
sed -i "s@\ENV_NAME=.*@ENV_NAME=$(cat /path/to/scripts/date)@g" /path/to/scripts/variables;
HOSTER_URL="http://appstore.hoster_domain"
DASHBOARD_APPID="JCA_dashboard_appID"
APPSTORE_APPID="JCA_appstore_appID"
CONTENT_TYPE="Content-Type: application/x-www-form-urlencoded; charset=UTF-8;";
USER_AGENT="Mozilla/4.73 [en] (X11; U; Linux 2.2.15 i686)"

echo "SignIn...";
signIn=$(curl \
-H "${CONTENT_TYPE}" \
-A "${USER_AGENT}" \
-fsS ${HOSTER_URL}'/1.0/users/authentication/rest/signin?login='$1'&password='$2);
echo 'Response signIn second user: '$signIn

RESULT=$(jq '.result' <<< $signIn );
SESSION=$( jq '.session' <<< $signIn |  sed 's/\"//g' ) ;

echo "GetEnvAppid...";
getEnvs=$(curl  \
-A "${USER_AGENT}" \
-H "${CONTENT_TYPE}" \
-X POST -fsS ${HOSTER_URL}"/1.0/environment/environment/rest/getenvs" --data "appid=${DASHBOARD_APPID}" --data "session=${SESSION}")
ENV_APPID=$( jq ".infos[] | select (.env.shortdomain==\"$(cat /path/to/scripts/date)\") | .env.appid" <<< $getEnvs |  sed 's/\"//g' ) ;
echo "Response GetEnvAppid: "$ENV_APPID;

echo "Installing envoronment...";
installApp=$(curl -i \
-A "${USER_AGENT}" \
-H "${CONTENT_TYPE}" \
-X POST -fsS ${HOSTER_URL}"/installapp" --data "session=${SESSION}" --data "shortdomain=$(cat /path/to/scripts/date)" --data-urlencode 'manifest=url_to_manifest');

echo "Response install env: "$installApp;
sleep 5s

