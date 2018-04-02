zypper_repository 'openSUSE-Leap-Cloud-Tools' do
  action :remove
end

zypper_package 'docker' do
  action :install
  options '--gpg-auto-import-keys'
end

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
    command: "-advertise=10.1.0.106 -server -retry-join=10.1.0.106 -bootstrap-expect=1"
    container_name: consul
    ports:
     - "8500:8500"
     - "8300:8300"
     - "8400:8400"
     - "8301:8301/tcp"
     - "8302:8302/tcp"
     - "8301:8301/udp"
     - "8302:8302/udp"
     - "53:8600/udp"'
end

execute 'docker-compose' do
  command '/usr/local/bin/docker-compose -f /home/docker-compose.yml up -d'
end
