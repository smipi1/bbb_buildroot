################################################################################
#
# barebox-2
#
################################################################################

# Instantiate a 2nd barebox package, built from the same sources as the 1st,
# but with it's own configuration:
$(eval $(barebox-package))
