include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PImportSB

PImportSB_FILES = /mnt/d/codes/PImport/pimportsb/PImportSB.xm

PImportSB_FRAMEWORKS = UIKit Foundation CoreFoundation CydiaSubstrate AssetsLibrary
PImportSB_CFLAGS = -fobjc-arc -std=c++11
PImportSB_LDFLAGS = -Wl,-segalign,4000
export ARCHS = armv7 arm64
PImportSB_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk

all::

	
