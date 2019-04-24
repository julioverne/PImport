include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PImport

PImport_FILES = /mnt/d/codes/PImport/pimporthook/PImport.xm
PImport_FILES += /mnt/d/codes/PImport/pimporthook/SimpleExif/ExifContainer.m

PImport_FRAMEWORKS = Foundation CydiaSubstrate UIKit CoreMedia CoreGraphics AVFoundation MobileCoreServices ImageIO QuartzCore CoreImage AssetsLibrary CoreLocation MapKit
PImport_PRIVATE_FRAMEWORKS = StoreServices Preferences
PImport_CFLAGS = -fobjc-arc
PImport_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
PImport_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
	
all::
	