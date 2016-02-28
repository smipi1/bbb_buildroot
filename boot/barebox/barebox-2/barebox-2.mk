################################################################################
#
# barebox-2
#
################################################################################

# Add support for a barebox-package:
# 1. Inherit the barebox-package logic from barebox
# 2. Use BAREBOX_2 as the uppercase package name.
# 3. Inherit the version and origin information from BAREBOX.

$(eval $(call barebox-package,BAREBOX_2,BAREBOX))
