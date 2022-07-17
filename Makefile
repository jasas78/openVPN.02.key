
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
helpTEXT1+=    $1   -> $($1) -> $($($1))$$(EOL)

endef

define callFUNC3
$1 : $($1)
helpTEXT1+=    $1   -> $($1)
$($1) :
    @echo
    $($($1))
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


m:
	vim Makefile
	
#
#
easy-rsa :
	git clone https://github.com/OpenVPN/easy-rsa.git

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

k1:=key101
key101:=keyS1/pki/ca.crt
key101 : 
	test -f EasyRSA.now/easyrsa || make easy-rsa_build
	test -f $($@) \
		&& echo \
		&& echo 'Already generated $($@), skip' \
		&& echo 'If you want to regen, manually delete it.' && echo \
		|| make gen_key101

# https://community.openvpn.net/openvpn/wiki/EasyRSA3-OpenVPN-Howto#PKIprocedure:ProducingyourcompletePKIontheCAmachine
gen_key101 :
	mkdir -p keyS1
	echo yes > keyS1/answer01_yes.txt
	cd keyS1 && ../EasyRSA.now/easyrsa      init-pki            < answer01_yes.txt
#	cd keyS1 && ../EasyRSA.now/easyrsa help build-ca 
	cd keyS1 && ../EasyRSA.now/easyrsa      build-ca nopass     < answer01_yes.txt
	ls -l keyS1/pki/ca.crt
	md5sum keyS1/pki/ca.crt
	mkdir -p keyS0
	cp keyS1/pki/ca.crt keyS0/key101_ca.crt_`md5sum keyS1/pki/ca.crt|awk '{printf $$1}'`
	@echo grep . keyS1/pki/ca.crt

k2:=key102
serverName:=Eaafb_mp4_server
key102:=keyS1/pki/issued/$(serverName).crt
key102x:=keyS1/pki/private/$(serverName).key
key102y:=keyS1/pki/reqs/$(serverName).req
key102:
	test -f EasyRSA.now/easyrsa || make easy-rsa_build
	test -f $($@) \
		&& echo \
		&& echo 'Already generated $($@), skip' \
		&& echo 'If you want to regen, manually delete it.' && echo \
		&& ls -l         $(key102) $(key102x) $(key102y) && echo \
		|| make gen_key201
gen_key201:
	@echo ========= $@
#	cd keyS1 && ../EasyRSA.now/easyrsa help build-server-full  
	test -f $(key102) \
		&& echo && echo '$(key102) already exist. skip' \
		&& ls -l         $(key102) $(key102x) $(key102y) && echo \
		|| ( cd keyS1 && ../EasyRSA.now/easyrsa      build-server-full  $(serverName) nopass )
	cp $(key102)  keyS0/key201_$(serverName).crt_`md5sum $(key102) |awk '{printf $$1}'`
	cp $(key102x) keyS0/key201_$(serverName).key_`md5sum $(key102x)|awk '{printf $$1}'`
	cp $(key102y) keyS0/key201_$(serverName).req_`md5sum $(key102y)|awk '{printf $$1}'`

c2:=clean_key201
clean_key201:
	rm -f $(wildcard $(key102) $(key102x) $(key102y))



helpX1:=\
	ep eb c2
helpX2:=\
	k1 k2

$(foreach aa1,$(helpX1),$(eval $(call callFUNC1,$(aa1))))
$(foreach aa1,$(helpX2),$(eval $(call callFUNC2,$(aa1))))
export helpTEXT1
export helpTEXT2

gs:
	git status
gc:
	git commit -a
ga:
	git add .
