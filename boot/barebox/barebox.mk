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

BAREBOX_KCONFIG_FRAGMENT_FILES = $(call qstrip,$(BR2_TARGET_BAREBOX_CONFIG_FRAGMENT_FILES))
BAREBOX_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig

include $(sort $(wildcard boot/barebox/*/*.mk))
