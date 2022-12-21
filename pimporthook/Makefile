include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PImport

$(TWEAK_NAME)_FILES = /mnt/d/codes/PImport/pimporthook/PImport.xm
$(TWEAK_NAME)_FILES += /mnt/d/codes/PImport/pimporthook/SimpleExif/ExifContainer.m

$(TWEAK_NAME)_FRAMEWORKS = Foundation CydiaSubstrate UIKit CoreMedia CoreGraphics AVFoundation MobileCoreServices ImageIO QuartzCore CoreImage AssetsLibrary CoreLocation MapKit
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = StoreServices Preferences
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 armv7s arm64 arm64e
$(TWEAK_NAME)_ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
