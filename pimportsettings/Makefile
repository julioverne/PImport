include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PImport
PImport_FILES = /mnt/d/codes/PImport/pimportsettings/PImportController.mm
PImport_INSTALL_PATH = /Library/PreferenceBundles
PImport_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter
PImport_PRIVATE_FRAMEWORKS = Preferences
PImport_CFLAGS = -fobjc-arc
PImport_LDFLAGS = -Wl,-segalign,4000
PImport_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/bundle.mk

all::
	