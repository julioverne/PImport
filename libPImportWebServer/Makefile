include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libPImportWebServer

libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebServer.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerConnection.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerDataResponse.m 
libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerFileRequest.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerFileResponse.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerFunctions.m 
libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerRequest.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerResponse.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerStreamedResponse.m 
libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerURLEncodedFormRequest.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerMultiPartFormRequest.m 
libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerDataRequest.m /mnt/d/codes/PImport/libPImportWebServer/PImportWebServerErrorResponse.m
libPImportWebServer_FILES += /mnt/d/codes/PImport/libPImportWebServer/PImportWebUploader.m

libPImportWebServer_INSTALL_PATH = /usr/lib
libPImportWebServer_FRAMEWORKS = UIKit Foundation CoreFoundation CydiaSubstrate CFNetwork MobileCoreServices AssetsLibrary Photos
libPImportWebServer_CFLAGS = -fobjc-arc -std=c++11
libPImportWebServer_LDFLAGS = -lz -Wl,-segalign,4000

libPImportWebServer_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/library.mk


