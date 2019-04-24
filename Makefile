include $(THEOS)/makefiles/common.mk

SUBPROJECTS += libPImportWebServer
SUBPROJECTS += pimporthook
SUBPROJECTS += pimportsb
SUBPROJECTS += pimportsettings

include $(THEOS_MAKE_PATH)/aggregate.mk

all::
	
