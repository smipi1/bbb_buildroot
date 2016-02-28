################################################################################
#
# barebox
#
################################################################################

BAREBOX_VERSION = $(call qstrip,$(BR2_TARGET_BAREBOX_VERSION))

ifeq ($(BAREBOX_VERSION),custom)
# Handle custom Barebox tarballs as specified by the configuration
BAREBOX_TARBALL = $(call qstrip,$(BR2_TARGET_BAREBOX_CUSTOM_TARBALL_LOCATION))
BAREBOX_SITE = $(patsubst %/,%,$(dir $(BAREBOX_TARBALL)))
BAREBOX_SOURCE = $(notdir $(BAREBOX_TARBALL))
BR_NO_CHECK_HASH_FOR += $(BAREBOX_SOURCE)
else ifeq ($(BR2_TARGET_BAREBOX_CUSTOM_GIT),y)
BAREBOX_SITE = $(call qstrip,$(BR2_TARGET_BAREBOX_CUSTOM_GIT_REPO_URL))
BAREBOX_SITE_METHOD = git
else
# Handle stable official Barebox versions
BAREBOX_SOURCE = barebox-$(BAREBOX_VERSION).tar.bz2
BAREBOX_SITE = http://www.barebox.org/download
ifeq ($(BR2_TARGET_BAREBOX_CUSTOM_VERSION),y)
BR_NO_CHECK_HASH_FOR += $(BAREBOX_SOURCE)
endif
endif

BAREBOX_DEPENDENCIES = host-lzop
BAREBOX_LICENSE = GPLv2 with exceptions
BAREBOX_LICENSE_FILES = COPYING

ifneq ($(call qstrip,$(BR2_TARGET_BAREBOX_CUSTOM_PATCH_DIR)),)
define BAREBOX_APPLY_CUSTOM_PATCHES
	$(APPLY_PATCHES) $(@D) \
		$(BR2_TARGET_BAREBOX_CUSTOM_PATCH_DIR) \*.patch
endef

BAREBOX_POST_PATCH_HOOKS += BAREBOX_APPLY_CUSTOM_PATCHES
endif

BAREBOX_INSTALL_IMAGES = YES
ifneq ($(BR2_TARGET_BAREBOX_BAREBOXENV),y)
BAREBOX_INSTALL_TARGET = NO
endif

ifeq ($(KERNEL_ARCH),i386)
BAREBOX_ARCH = x86
else ifeq ($(KERNEL_ARCH),x86_64)
BAREBOX_ARCH = x86
else ifeq ($(KERNEL_ARCH),powerpc)
BAREBOX_ARCH = ppc
else
BAREBOX_ARCH = $(KERNEL_ARCH)
endif

BAREBOX_MAKE_FLAGS = ARCH=$(BAREBOX_ARCH) CROSS_COMPILE="$(TARGET_CROSS)"
BAREBOX_MAKE_ENV = $(TARGET_MAKE_ENV)

# Re-usable barebox KConfig logic (needed by barebox-2)
define BAREBOX_KCONFIG
ifeq ($$(BR2_TARGET_$(1)_USE_DEFCONFIG),y)
$(1)_KCONFIG_DEFCONFIG = $$(call qstrip,$$(BR2_TARGET_$(1)_BOARD_DEFCONFIG))_defconfig
else ifeq ($$(BR2_TARGET_$(1)_USE_CUSTOM_CONFIG),y)
$(1)_KCONFIG_FILE = $$(call qstrip,$$(BR2_TARGET_$(1)_CUSTOM_CONFIG_FILE))
endif

$(1)_KCONFIG_FRAGMENT_FILES = $$(call qstrip,$$(BR2_TARGET_$(1)_CONFIG_FRAGMENT_FILES))
$(1)_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig
$(1)_KCONFIG_OPTS = $$(BAREBOX_MAKE_FLAGS)
endef
$(eval $(call BAREBOX_KCONFIG,BAREBOX))

ifeq ($(BR2_TARGET_BAREBOX_BAREBOXENV),y)
define BAREBOX_BUILD_BAREBOXENV_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -o $(@D)/bareboxenv \
		$(@D)/scripts/bareboxenv.c
endef
endif

# Re-usable barebox custom env logic (needed by barebox-2)
define BAREBOX_CUSTOM_ENV
ifeq ($$(BR2_TARGET_$(1)_CUSTOM_ENV),y)
$(1)_ENV_NAME = $$(notdir $$(call qstrip,\
	$$(BR2_TARGET_$(1)_CUSTOM_ENV_PATH)))
define $(1)_BUILD_CUSTOM_ENV
	$$(@D)/scripts/bareboxenv -s \
		$$(call qstrip, $$(BR2_TARGET_$(1)_CUSTOM_ENV_PATH)) \
		$$(@D)/$$($(1)_ENV_NAME)
endef
define $(1)_INSTALL_CUSTOM_ENV
	cp $$(@D)/$$($(1)_ENV_NAME) $$(BINARIES_DIR)
endef
endif
endef
$(eval $(BAREBOX_CUSTOM_ENV,BAREBOX))

define BAREBOX_BUILD_CMDS
	$($(PKG)_BUILD_BAREBOXENV_CMDS)
	$(TARGET_MAKE_ENV) $(MAKE) $(BAREBOX_MAKE_FLAGS) -C $(@D)
	$($(PKG)_BUILD_CUSTOM_ENV)
endef

define BAREBOX_INSTALL_IMAGES_CMDS
	if test -e $(@D)/$(call qstrip,$(BR2_TARGET_$(PKG)_BUILT_IMAGE_FILE)); then \
		cp -L $(@D)/$(call qstrip,$(BR2_TARGET_$(PKG)_BUILT_IMAGE_FILE)) \
		      $(BINARIES_DIR)/$(call qstrip,$(BR2_TARGET_$(PKG)_OUTPUT_IMAGE_FILE)) ; \
	else \
		cp $(@D)/images/$(call qstrip,$(BR2_TARGET_$(PKG)_BUILT_IMAGE_FILE)) \
		   $(BINARIES_DIR)/$(call qstrip,$(BR2_TARGET_$(PKG)_OUTPUT_IMAGE_FILE)) ; \
	fi
	$($(PKG)_INSTALL_CUSTOM_ENV)
endef

ifeq ($(BR2_TARGET_BAREBOX_BAREBOXENV),y)
define BAREBOX_INSTALL_TARGET_CMDS
	cp $(@D)/bareboxenv $(TARGET_DIR)/usr/bin
endef
endif


# Re-usable errors that the user can understand (needed by barebox-2)
define BAREBOX_USER_FRIENDLY_ERRORS
# Checks to give errors that the user can understand
# Must be before we call to kconfig-package
ifeq ($$(BR2_TARGET_$(1))$$(BR_BUILDING),yy)
# We must use the user-supplied kconfig value, because
# BAREBOX_KCONFIG_DEFCONFIG will at least contain the
# trailing _defconfig
ifeq ($$(or $$($(1)_KCONFIG_FILE),$$(call qstrip,$$(BR2_TARGET_$(1)_BOARD_DEFCONFIG))),)
$$(error No Barebox config. Check your BR2_TARGET_$(1)_BOARD_DEFCONFIG or BR2_TARGET_$(1)_CUSTOM_CONFIG_FILE settings)
endif
ifndef BR2_TARGET_$(1)_BUILT_IMAGE_FILE
$$(error No barebox built image filename specified. Check your BR2_TARGET_$(1)_BUILT_IMAGE_FILE setting)
endif
ifndef BR2_TARGET_$(1)_OUTPUT_IMAGE_FILE
$$(error No barebox output image filename specified. Check your BR2_TARGET_$(1)_OUTPUT_IMAGE_FILE setting)
endif
endif
endef
$(eval $(call BAREBOX_USER_FRIENDLY_ERRORS,BAREBOX))

$(eval $(kconfig-package))

include boot/barebox/barebox-2/barebox-2.mk
