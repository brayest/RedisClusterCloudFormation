apt_update 'Update the apt cache daily' do
  frequency 86_400
  action :periodic
end

package 'docker.io'

service 'docker' do
  supports status: true
  action [:enable, :start]
end

remote_file '/usr/local/bin/docker-compose' do
  source 'https://github.com/docker/compose/releases/download/1.20.1/docker-compose-Linux-x86_64'
  mode '0755'
  action :create
end

file '/home/docker-compose.yml' do
  content 'version: "3"

services:

  consul:
    image:  gliderlabs/consul-server:latest
    command: "-advertise=$LOCAL_IP -retry-join=10.1.0.106"
    container_name: consul
    ports:
     - "8500:8500"
     - "8300:8300"
     - "8400:8400"
     - "8301:8301/tcp"
     - "8302:8302/tcp"
     - "8301:8301/udp"
     - "8302:8302/udp"
     - "53:8600/udp"

  registrator:
    image: gliderlabs/registrator:latest
    command: "-ip $LOCAL_IP consul://$LOCAL_IP:8500"
    container_name: registrator
    depends_on:
    - consul
    volumes:
    - /var/run/docker.sock:/tmp/docker.sock

  redismaster:
    container_name: redismaster
    labels:
    - "SERVICE_NAME=master"
    image: redis
    ports:
      - 6379:6379
    restart: always
    depends_on:
      - registrator'
end

execute 'docker-compose' do
  command 'export LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) && /usr/local/bin/docker-compose -f /home/docker-compose.yml up -d'
end
