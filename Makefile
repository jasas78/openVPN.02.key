
ifeq ($(USER),root)
    $(info )
    $(info "$0 can't run by $(USER). exit." )
    $(info )
    $(error exit )
endif

dateX1:=$(shell LC_ALL=C date +%Y_%m%d_%H%M%P_%S )

define EOL


endef
define callFUNC
$1 : $($1)
$$(eval helpTEXT1+=    $1   -> $($1))
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

m:
	vim Makefile
	
#
#
easy-rsa :
	git clone https://github.com/OpenVPN/easy-rsa.git
easy-rsa_pull : easy-rsa
	cd easy-rsa && git pull
easy-rsa_build : easy-rsa_pull 
	cd easy-rsa && git log
