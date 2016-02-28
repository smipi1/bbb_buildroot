################################################################################
#
# barebox
#
################################################################################

################################################################################
# barebox-package -- generates the KConfig logic and make targets needed to
# support a barebox package
################################################################################

define barebox-package

BAREBOX_VERSION = $$(call qstrip,$$(BR2_TARGET_BAREBOX_VERSION))

ifeq ($$(BAREBOX_VERSION),custom)
# Handle custom Barebox tarballs as specified by the configuration
BAREBOX_TARBALL = $$(call qstrip,$$(BR2_TARGET_BAREBOX_CUSTOM_TARBALL_LOCATION))
BAREBOX_SITE = $$(patsubst %/,%,$$(dir $$(BAREBOX_TARBALL)))
BAREBOX_SOURCE = $$(notdir $$(BAREBOX_TARBALL))
BR_NO_CHECK_HASH_FOR += $$(BAREBOX_SOURCE)
else ifeq ($$(BR2_TARGET_BAREBOX_CUSTOM_GIT),y)
BAREBOX_SITE = $$(call qstrip,$$(BR2_TARGET_BAREBOX_CUSTOM_GIT_REPO_URL))
BAREBOX_SITE_METHOD = git
else
# Handle stable official Barebox versions
BAREBOX_SOURCE = barebox-$$(BAREBOX_VERSION).tar.bz2
BAREBOX_SITE = http://www.barebox.org/download
ifeq ($$(BR2_TARGET_BAREBOX_CUSTOM_VERSION),y)
BR_NO_CHECK_HASH_FOR += $$(BAREBOX_SOURCE)
endif
endif

BAREBOX_DEPENDENCIES = host-lzop
BAREBOX_LICENSE = GPLv2 with exceptions
BAREBOX_LICENSE_FILES = COPYING

ifneq ($$(call qstrip,$$(BR2_TARGET_BAREBOX_CUSTOM_PATCH_DIR)),)
define BAREBOX_APPLY_CUSTOM_PATCHES
	$$(APPLY_PATCHES) $$(@D) \
		$$(BR2_TARGET_BAREBOX_CUSTOM_PATCH_DIR) \*.patch
endef

BAREBOX_POST_PATCH_HOOKS += BAREBOX_APPLY_CUSTOM_PATCHES
endif

BAREBOX_INSTALL_IMAGES = YES
ifneq ($$(BR2_TARGET_BAREBOX_BAREBOXENV),y)
BAREBOX_INSTALL_TARGET = NO
endif

ifeq ($$(KERNEL_ARCH),i386)
BAREBOX_ARCH = x86
else ifeq ($$(KERNEL_ARCH),x86_64)
BAREBOX_ARCH = x86
else ifeq ($$(KERNEL_ARCH),powerpc)
BAREBOX_ARCH = ppc
else
BAREBOX_ARCH = $$(KERNEL_ARCH)
endif

BAREBOX_MAKE_FLAGS = ARCH=$$(BAREBOX_ARCH) CROSS_COMPILE="$$(TARGET_CROSS)"
BAREBOX_MAKE_ENV = $$(TARGET_MAKE_ENV)

ifeq ($$(BR2_TARGET_BAREBOX_USE_DEFCONFIG),y)
BAREBOX_KCONFIG_DEFCONFIG = $$(call qstrip,$$(BR2_TARGET_BAREBOX_BOARD_DEFCONFIG))_defconfig
else ifeq ($$(BR2_TARGET_BAREBOX_USE_CUSTOM_CONFIG),y)
BAREBOX_KCONFIG_FILE = $$(call qstrip,$$(BR2_TARGET_BAREBOX_CUSTOM_CONFIG_FILE))
endif

BAREBOX_KCONFIG_FRAGMENT_FILES = $$(call qstrip,$$(BR2_TARGET_BAREBOX_CONFIG_FRAGMENT_FILES))
BAREBOX_KCONFIG_EDITORS = menuconfig xconfig gconfig nconfig
BAREBOX_KCONFIG_OPTS = $$(BAREBOX_MAKE_FLAGS)

ifeq ($$(BR2_TARGET_BAREBOX_BAREBOXENV),y)
define BAREBOX_BUILD_BAREBOXENV_CMDS
	$$(TARGET_CC) $$(TARGET_CFLAGS) $$(TARGET_LDFLAGS) -o $$(@D)/bareboxenv \
		$$(@D)/scripts/bareboxenv.c
endef
endif

ifeq ($$(BR2_TARGET_BAREBOX_CUSTOM_ENV),y)
BAREBOX_ENV_NAME = $$(notdir $$(call qstrip,\
	$$(BR2_TARGET_BAREBOX_CUSTOM_ENV_PATH)))
define BAREBOX_BUILD_CUSTOM_ENV
	$$(@D)/scripts/bareboxenv -s \
		$$(call qstrip, $$(BR2_TARGET_BAREBOX_CUSTOM_ENV_PATH)) \
		$$(@D)/$$(BAREBOX_ENV_NAME)
endef
define BAREBOX_INSTALL_CUSTOM_ENV
	cp $$(@D)/$$(BAREBOX_ENV_NAME) $$(BINARIES_DIR)
endef
endif

define BAREBOX_BUILD_CMDS
	$$(BAREBOX_BUILD_BAREBOXENV_CMDS)
	$$(TARGET_MAKE_ENV) $$(MAKE) $$(BAREBOX_MAKE_FLAGS) -C $$(@D)
	$$(BAREBOX_BUILD_CUSTOM_ENV)
endef

define BAREBOX_INSTALL_IMAGES_CMDS
	if test -e $$(@D)/$$(call qstrip,$$(BR2_TARGET_BAREBOX_BUILT_IMAGE_FILE)); then \
		cp -L $$(@D)/$$(call qstrip,$$(BR2_TARGET_BAREBOX_BUILT_IMAGE_FILE)) \
		      $$(BINARIES_DIR)/$$(call qstrip,$$(BR2_TARGET_BAREBOX_OUTPUT_IMAGE_FILE)) ; \
	else \
		cp $$(@D)/images/$$(call qstrip,$$(BR2_TARGET_BAREBOX_BUILT_IMAGE_FILE)) \
		   $$(BINARIES_DIR)/$$(call qstrip,$$(BR2_TARGET_BAREBOX_OUTPUT_IMAGE_FILE)) ; \
	fi
	$$(BAREBOX_INSTALL_CUSTOM_ENV)
endef

ifeq ($$(BR2_TARGET_BAREBOX_BAREBOXENV),y)
define BAREBOX_INSTALL_TARGET_CMDS
	cp $$(@D)/bareboxenv $$(TARGET_DIR)/usr/bin
endef
endif

# Checks to give errors that the user can understand
# Must be before we call to kconfig-package
ifeq ($$(BR2_TARGET_BAREBOX)$$(BR_BUILDING),yy)
# We must use the user-supplied kconfig value, because
# BAREBOX_KCONFIG_DEFCONFIG will at least contain the
# trailing _defconfig
ifeq ($$(or $$(BAREBOX_KCONFIG_FILE),$$(call qstrip,$$(BR2_TARGET_BAREBOX_BOARD_DEFCONFIG))),)
$$(error No Barebox config. Check your BR2_TARGET_BAREBOX_BOARD_DEFCONFIG or BR2_TARGET_BAREBOX_CUSTOM_CONFIG_FILE settings)
endif
ifndef BR2_TARGET_BAREBOX_BUILT_IMAGE_FILE
$$(error No barebox built image filename specified. Check your BR2_TARGET_BAREBOX_BUILT_IMAGE_FILE setting)
endif
ifndef BR2_TARGET_BAREBOX_OUTPUT_IMAGE_FILE
$$(error No barebox output image filename specified. Check your BR2_TARGET_BAREBOX_OUTPUT_IMAGE_FILE setting)
endif
endif

$$(eval $$(kconfig-package))
endef

$(eval $(call barebox-package))
