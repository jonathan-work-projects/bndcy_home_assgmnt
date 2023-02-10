#!bin/bash
user=admin
psw=bindecy

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
pushd docker
docker build -t bindecy:1.0 .
docker run -d --name jenkins-bindecy -p 8080:8080 jenkins-bindecy:1.0
popd

read -p "Waiting a bit for docker instance to startup.." -t 7

# access jenkins api
crumb=$(curl -v -X GET http://localhost:8080/crumbIssuer/api/json --user $user:$psw  \
-H "Cookie: JSESSIONID.56e4b3b7=node0xsbnd4uu2dt41j69vxgq0zfml1.node0; JSESSIONID.fd4e3cc2=node0sv2b0t44x0wq10eyfiohqnomq22.node0" | jq -r '.crumb')

#configure secrets
pushd jenkins/creds
for file in *
do
data=$(cat $file)
curl -X POST http://localhost:8080/manage/credentials/store/system/domain/_/createCredentials --user $user:$psw\
    -H "Cookie: JSESSIONID.56e4b3b7=node0xsbnd4uu2dt41j69vxgq0zfml1.node0; JSESSIONID.fd4e3cc2=node0sv2b0t44x0wq10eyfiohqnomq22.node0" \
    -H "Content-Type:application/xml" \
    -H "Jenkins-Crumb: $crumb" \
    --data-raw "$data"
done
popd 

pushd jenkins/pipelines
for file in *
do
data=$(cat $file)
curl -X POST http://localhost:8080/createItem?name=${file%.*} --user $user:$psw \
    -H "Cookie: JSESSIONID.56e4b3b7=node0xsbnd4uu2dt41j69vxgq0zfml1.node0; JSESSIONID.fd4e3cc2=node0sv2b0t44x0wq10eyfiohqnomq22.node0" \
    -H "Content-Type:application/xml" \
    -H "Jenkins-Crumb: $crumb" \
    --data "$data"
done
popd
echo $crumb