sudo http_proxy='http://10.110.15.61:8080' apt-get update
sudo http_proxy='http://10.110.15.61:8080' apt-get -y install ubuntu-cloud-keyring python-software-properties software-properties-common python-keyring
sudo echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/havana main >> /etc/apt/sources.list.d/havana.list
sudo  http_proxy='http://10.110.15.61:8080' apt-get install python-software-properties
sudo  http_proxy='http://10.110.15.61:8080' add-apt-repository cloud-archive:havana
sudo  http_proxy='http://10.110.15.61:8080' apt-get -y update && sudo  http_proxy='http://10.110.15.61:8080' apt-get -y upgrade && sudo  http_proxy='http://10.110.15.61:8080'  apt-get -y dist-upgrade
