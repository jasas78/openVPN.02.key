
ifeq ($(USER),root)
    $(info )
    $(info "$0 can't run by $(USER). exit." )
    $(info )
    $(error exit )
endif

dateX1:=$(shell LC_ALL=C date +%Y_%m%d_%H%M%P_%S )

define EOL


endef

define callFUNC1
$1 : $($1)
helpTEXT1+=    $1   -> $($1)$$(EOL)

endef

define callFUNC2
$1 : $($1)
helpTEXT2+=    $1   -> $($1) -> $($($1))$$(EOL)

endef

define callFUNC3
helpTEXT3+=    $1   -> $($1)$$(EOL)
$1 :
	@echo
	$($1)

endef

PWD         := $(shell pwd)
KVERSION    := $(shell uname -r)
KERNEL_DIR  ?= /lib/modules/$(KVERSION)/build


makefile_real:=$(shell realpath Makefile)
makefile_dir:=$(shell dirname $(makefile_real))

uname_p:=$(shell uname -p)




all:
	@echo " $${helpTEXT1}"
	@echo " $${helpTEXT2}"
	@echo " $${helpTEXT3}"


m:=vim Makefile
	
#
#
easy-rsa :
	git clone https://github.com/OpenVPN/easy-rsa.git

easy-tls : 
	git clone https://github.com/TinCanTech/easy-tls.git

ep:=easy-rsa_pull

easy-rsa_pull : easy-rsa
	cd easy-rsa && git pull

EasyRSA.now/easyrsa : easy-rsa_build

eb:=easy-rsa_build

easy-rsa_build : easy-rsa_pull 
	cd easy-rsa \
		&& easyRsaVERSION=$$(git tag |grep -v \\\-rc |sort |tail -n 1|awk '{printf $$1}') \
		&& echo "easyRsaVERSION == $${easyRsaVERSION}" \
		&& rm -fr ./dist-staging/ \
		&& ./build/build-dist.sh  --version=$${easyRsaVERSION} \
		&& cd ../ \
		&& rm -f EasyRSA.now \
		&& ln -s easy-rsa/dist-staging/unix/EasyRSA-$${easyRsaVERSION}/ EasyRSA.now \
		&& EasyRSA.now/easyrsa --version

eh:=easy-rsa_help
easy-rsa_help:
	@test -f EasyRSA.now/easyrsa || make easy-rsa_build
	EasyRSA.now/easyrsa --help

k1:=key101
key101:=keyS1/pki/ca.crt
key101 : 
	@test -f EasyRSA.now/easyrsa || make easy-rsa_build
	test -f $($@) \
		&& echo \
		&& echo 'Already generated $($@), skip' \
		&& echo 'If you want to regen, manually delete it.' && echo \
		|| make gen_key101
	test -L keyS0/_key101_ca.crt \
		|| make gen_key101LN

# https://community.openvpn.net/openvpn/wiki/EasyRSA3-OpenVPN-Howto#PKIprocedure:ProducingyourcompletePKIontheCAmachine
gen_key101 :
	mkdir -p keyS1
	echo yes > keyS1/answer01_yes.txt
	cd keyS1 && ../EasyRSA.now/easyrsa      init-pki            < answer01_yes.txt
#	cd keyS1 && ../EasyRSA.now/easyrsa help build-ca 
	cd keyS1 && ../EasyRSA.now/easyrsa      build-ca nopass     < answer01_yes.txt
	ls -l keyS1/pki/ca.crt
	md5sum keyS1/pki/ca.crt

gen_key101LN:
	mkdir -p keyS0
	cp $(key101) keyS0/key101_ca.crt_$(dateX1)_`md5sum keyS1/pki/ca.crt|awk '{printf $$1}'`.crt
	rm -f keyS0/_key101_ca.crt
	cd keyS0 && ln -s key101_ca.crt_$(dateX1)_`md5sum ../keyS1/pki/ca.crt|awk '{printf $$1}'`.crt  _key101_ca.crt
	@echo grep . keyS1/pki/ca.crt

k2:=key201
serverName:=Eaafb_mp4_server
key201:=keyS1/pki/issued/$(serverName).crt
key201x:=keyS1/pki/private/$(serverName).key
key201y:=keyS1/pki/reqs/$(serverName).req
key201:
	test -f EasyRSA.now/easyrsa || make easy-rsa_build
	make gen_$@
gen_key201:
	@echo ========= $@
#	cd keyS1 && ../EasyRSA.now/easyrsa help build-server-full  
	test -f $(key201) \
		&& echo && echo '$(key201) already exist. skip' \
		&& ls -l         $(key201) $(key201x) $(key201y) && echo \
		|| ( cd keyS1 && ../EasyRSA.now/easyrsa      build-server-full  $(serverName) nopass )
	cp  $(key201)  keyS0/key201_$(serverName).crt_$(dateX1)_`md5sum $(key201) |awk '{printf $$1}'`.crt
	@cp $(key201x) keyS0/key201_$(serverName).key_$(dateX1)_`md5sum $(key201x)|awk '{printf $$1}'`.key
	@cp $(key201y) keyS0/key201_$(serverName).req_$(dateX1)_`md5sum $(key201y)|awk '{printf $$1}'`.req
	rm -f keyS0/_key201_$(serverName).crt keyS0/_key201_$(serverName).key keyS0/_key201_$(serverName).req 
	cd keyS0  && ln -s  key201_$(serverName).crt_$(dateX1)_`md5sum ../$(key201)  |awk '{printf $$1}'`.crt _key201_$(serverName).crt
	@cd keyS0 && ln -s  key201_$(serverName).key_$(dateX1)_`md5sum ../$(key201x) |awk '{printf $$1}'`.key _key201_$(serverName).key
	@cd keyS0 && ln -s  key201_$(serverName).req_$(dateX1)_`md5sum ../$(key201y) |awk '{printf $$1}'`.req _key201_$(serverName).req

c2:=clean_key201
clean_key201:
	rm -f $(wildcard $(key201) $(key201x) $(key201y))

k3:=key301
clientName:=Eaafb_mp4_client
clientAmount:=3
clientNameS:=$(foreach aa1,$(shell bb1=20;bb2=$$((20+$(clientAmount))); while [ $${bb1} -lt $${bb2} ] ; do \
	echo $${bb1};bb1=$$(($${bb1}+1));done),$(clientName)_$(aa1))
clientName1:=$(firstword $(clientNameS))
$(iinfo clientNameS<$(clientNameS)>, [$(clientName1)] )

key301:=keyS1/pki/issued/$(clientName1).crt
key301N=keyS1/pki/issued/$(clientNameN).crt
key301X=keyS1/pki/private/$(clientNameN).key
key301Y=keyS1/pki/reqs/$(clientNameN).req

key301:
	test -f EasyRSA.now/easyrsa || make easy-rsa_build
	$(foreach aa1,$(clientNameS), \
		@make gen_$@ -e clientNameN=$(aa1) $(EOL))

gen_key301:
	@echo ========= $@
#	cd keyS1 && ../EasyRSA.now/easyrsa help build-client-full  
	test -f $(key301N) \
		&& echo && echo '$(key301N) already exist. skip' \
		&& ls -l         $(key301N) $(key301X) $(key301Y) && echo \
		|| ( cd keyS1 && ../EasyRSA.now/easyrsa      build-client-full  $(clientNameN) nopass )
	cp  $(key301N)  keyS0/key301_$(clientNameN).crt_$(dateX1)_`md5sum $(key301N) |awk '{printf $$1}'`.crt
	@cp $(key301X)  keyS0/key301_$(clientNameN).key_$(dateX1)_`md5sum $(key301X) |awk '{printf $$1}'`.key
	@cp $(key301Y)  keyS0/key301_$(clientNameN).req_$(dateX1)_`md5sum $(key301Y) |awk '{printf $$1}'`.req
	rm -f \
		keyS0/_key301_$(clientNameN).crt \
		keyS0/_key301_$(clientNameN).key \
		keyS0/_key301_$(clientNameN).req
	cd keyS0  && ln -s  key301_$(clientNameN).crt_$(dateX1)_`md5sum ../$(key301N) |awk '{printf $$1}'`.crt _key301_$(clientNameN).crt
	@cd keyS0 && ln -s  key301_$(clientNameN).key_$(dateX1)_`md5sum ../$(key301X) |awk '{printf $$1}'`.key _key301_$(clientNameN).key
	@cd keyS0 && ln -s  key301_$(clientNameN).req_$(dateX1)_`md5sum ../$(key301Y) |awk '{printf $$1}'`.req _key301_$(clientNameN).req

c3:=clean_key301
clean_key301:
	$(foreach aa1,$(clientNameS), @make clean_key301R -e clientNameN=$(aa1) $(EOL))
clean_key301R:
	rm -f $(wildcard $(key301N) $(key301X) $(key301Y) )

# https://community.openvpn.net/openvpn/wiki/EasyRSA3-OpenVPN-Howto#PKIprocedure:ProducingyourcompletePKIontheCAmachine
t1:=tls01
t1h:=tls01_help
tls01:
	-cd keyS1/ && ../easy-tls/easytls init
	-cd keyS1/ && ../easy-tls/easytls rehash
	-cd keyS1/ && PATH=/ov/sbin/:$${PATH} ../easy-tls/easytls build-tls-auth
	-cd keyS1/ && PATH=/ov/sbin/:$${PATH} ../easy-tls/easytls build-tls-crypt
	-cd keyS1/ && PATH=/ov/sbin/:$${PATH} ../easy-tls/easytls build-tls-crypt-v2-server  $(serverName)
	$(foreach aa1,$(clientNameS), -cd keyS1/ \
		&&        PATH=/ov/sbin/:$${PATH} ../easy-tls/easytls build-tls-crypt-v2-client  $(serverName) $(aa1) $(EOL))
tls01_help:
	cd keyS1/ && ../easy-tls/easytls help

# https://community.openvpn.net/openvpn/wiki/EasyRSA3-OpenVPN-Howto

k4:=key401_dh
key401_dh:=keyS1/pki/dh.pem
key401_dhX:=_key401_dh.pem
key401_dh:
	@test -f EasyRSA.now/easyrsa || make easy-rsa_build
	test -f $($@) \
		&& echo \
		&& echo 'Already generated $($@), skip' \
		&& echo 'If you want to regen, manually delete it.' && echo \
		|| ( \
		cd keyS1 && ../EasyRSA.now/easyrsa      gen-dh \
		)
	@test -L keyS0/$(key401_dhX) && ls -l keyS0/$(key401_dhX) \
		|| make gen_key401DH
gen_key401DH:
	mkdir -p keyS0
	cp $(key401_dh)   keyS0/key401_dh.pem_$(dateX1)_`md5sum keyS1/pki/dh.pem|awk '{printf $$1}'`.pem
	rm -f keyS0/$(key401_dhX)
	cd keyS0 && ln -s key401_dh.pem_$(dateX1)_`md5sum ../keyS1/pki/dh.pem|awk '{printf $$1}'`.pem  $(key401_dhX)

css:=copy_server_conf
csc:=copy_client_conf

copy_server_conf:=conf_server
copy_server_confX:=$(copy_server_conf)/etc/openvpn/keys
copy_server_confY:=/ov/tmp/conf_server.conf
copy_server_conf:
	rm -fr       $($@)/
	mkdir -p     $($@X)/
	chmod 750    $($@)/
	cp	keyS0/_key101_ca.crt				$($@X)/ca.crt
	cp 	keyS0/_key401_dh.pem                $($@X)/dh2048.pem
	cp 	keyS0/_key201_$(serverName).crt  	$($@X)/$(serverName).crt
	cp 	keyS0/_key201_$(serverName).key 	$($@X)/$(serverName).key
	echo "$${server_conf}" >  $($@X)/../server.conf
	test ! -d `dirname $(copy_server_confY)` \
		|| echo "$${server_conf}" >  $(copy_server_confY)


copy_client_conf:=conf_client
copy_client_confX=$(copy_client_conf)/$(clientNameN)/etc/openvpn/keys
copy_client_conf:
	rm -fr       $($@)/
	$(foreach aa1,$(clientNameS), @make copy_client_confR -e clientNameN=$(aa1) $(EOL))

copy_client_confR:
	mkdir -p     $(copy_client_confX)/
	chmod 750    $(copy_client_conf)/$(clientNameN)/
#	cp	keyS0/_key101_ca.crt				$(copy_client_confX)/ca.crt
#	cp 	keyS0/_key401_dh.pem                $(copy_client_confX)/dh2048.pem
	cp 	keyS0/_key301_$(clientNameN).crt  	$(copy_client_confX)/$(clientNameN).crt
	cp 	keyS0/_key301_$(clientNameN).key 	$(copy_client_confX)/$(clientNameN).key

vpn_port:=32194
vpn_protocol:=tcp ### udp , tcp-server , tcp-client
vpn_tun_ipv4:=172.16.162.0
vpn_route_ip:=192.168.14.0
serverDomain:=eaafb.com

vpn_protocol:=$(strip $(vpn_protocol))
ifeq ($(vpn_protocol),tcp)
vpn_protocol_server:=tcp-server
vpn_protocol_client:=tcp-client
endif
ifeq ($(vpn_protocol),udp)
vpn_protocol_server:=udp
vpn_protocol_client:=udp
endif

define server_conf
mode server
proto 			$(vpn_protocol_server)
dev 			tun
lport 			$(vpn_port)

tls-server
ca 		/etc/openvpn/keys/ca.crt
cert 	/etc/openvpn/keys/$(serverName).crt
key 	/etc/openvpn/keys/$(serverName).key  # This file should be kept secret
dh 		/etc/openvpn/keys/dh2048.pem

#chroot /ch2
chroot /

topology subnet



comp-lzo
#management 				127.0.0.1 			$(vpn_port)
#keepalive 				10 					120
persist-key
persist-tun
ifconfig-pool-persist 	/tmp/openvpn-ipp.txt
status 					/tmp/openvpn-status.$(serverName).log
verb 					3
server 					$(vpn_tun_ipv4) 	255.255.255.0
push 	"route 			$(vpn_route_ip) 	255.255.255.0"
push 	"dhcp-option 	DNS 				8.8.8.8"
push 	"dhcp-option 	DOMAIN 				$(serverDomain)"

#up /tmp/vpn_log/chroot_openvpn.dir/mtu.sh__1200.sh

script-security 2

push "topology subnet"
ifconfig 10.70.70.1 255.255.255.0
push "route-gateway 10.70.70.1"
#ifconfig-pool 10.70.70.20 10.70.70.99 255.255.255.0
#client-config-dir /home/bootH/OpenVZ/h2/etc/openvpn.server/ccd-dir
client-to-client



#server 10.70.70.0 255.255.255.0



#ping 26
#ping-restart 156
keepalive 26 2006
hand-window 132

cipher AES-256-CBC
data-ciphers AES-256-CBC
auth sha256
prng sha256

#user nobody
#user 65534
#group nogroup

persist-key
persist-tun

verb 3


endef
export server_conf

# tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 500
#    link/none
#    inet 172.16.162.1/24 scope global tun0
#       valid_lft forever preferred_lft forever
#default via 192.168.14.1 dev eth0
#172.16.162.0/24 dev tun0 proto kernel scope link src 172.16.162.1



gs:= git status
gc:= git commit -a
gcX:= git commit -a -m '$(dateX1)'
ga:= git add .
up:= git push
X:= make gcX up

helpX1:=\
	ep eb c2 c3 t1 t1h eh css csc
helpX2:=\
	k1 k2 k3 k4
helpX3:=\
	m gs ga gc gcX up X

$(foreach aa1,$(helpX1),$(eval $(call callFUNC1,$(aa1))))
$(foreach aa1,$(helpX2),$(eval $(call callFUNC2,$(aa1))))
$(foreach aa1,$(helpX3),$(eval $(call callFUNC3,$(aa1))))
export helpTEXT1
export helpTEXT2
export helpTEXT3

