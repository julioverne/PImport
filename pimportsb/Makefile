include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PImportSB

$(TWEAK_NAME)_FILES = /mnt/d/codes/PImport/pimportsb/PImportSB.xm

$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreFoundation CydiaSubstrate AssetsLibrary
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -std=c++11
$(TWEAK_NAME)_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 armv7s arm64 arm64e
$(TWEAK_NAME)_ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
