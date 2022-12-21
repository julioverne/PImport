include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libPImportWebServer

$(LIBRARY_NAME)_FILES = $(wildcard /mnt/d/codes/PImport/libPImportWebServer/*.m)

$(LIBRARY_NAME)_INSTALL_PATH = /usr/lib
$(LIBRARY_NAME)_FRAMEWORKS = UIKit Foundation CoreFoundation CFNetwork MobileCoreServices AssetsLibrary Photos
$(LIBRARY_NAME)_CFLAGS = -fobjc-arc -std=c++11
$(LIBRARY_NAME)_LDFLAGS = -lz -Wl,-segalign,4000

$(LIBRARY_NAME)_ARCHS = armv7 armv7s arm64 arm64e
export ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS_MAKE_PATH)/library.mk
