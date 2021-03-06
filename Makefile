export TARGET = iphone:latest:12.0

FRAMEWORK_OUTPUT_DIR = $(THEOS_OBJ_DIR)/xcode_derived/install/Library/Frameworks
ALDERIS_SDK_DIR = $(THEOS_OBJ_DIR)/alderis_sdk_$(THEOS_PACKAGE_BASE_VERSION)

export ADDITIONAL_CFLAGS = -fobjc-arc -Wextra -Wno-unused-parameter -F$(FRAMEWORK_OUTPUT_DIR)
export ADDITIONAL_LDFLAGS = -F$(FRAMEWORK_OUTPUT_DIR)

INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Alderis

Alderis_XCODEFLAGS = DYLIB_INSTALL_NAME_BASE=/Library/Frameworks BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS="$(ARCHS)"

SUBPROJECTS = lcpshim

include $(THEOS_MAKE_PATH)/xcodeproj.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-Alderis-stage::
	@# Copy postinst
	@mkdir -p $(THEOS_STAGING_DIR)/DEBIAN
	@cp postinst $(THEOS_STAGING_DIR)/DEBIAN

docs:
	$(ECHO_BEGIN)$(PRINT_FORMAT_MAKING) "Generating docs"; jazzy --module-version $(THEOS_PACKAGE_BASE_VERSION)$(ECHO_END)
	$(ECHO_NOTHING)rm -rf docs/screenshots/ docs/docsets/Alderis.docset/Contents/Resources/Documents/screenshots/$(ECHO_END)
	$(ECHO_NOTHING)cp -r screenshots/ docs/screenshots/$(ECHO_END)
	$(ECHO_NOTHING)cp -r screenshots/ docs/docsets/Alderis.docset/Contents/Resources/Documents/screenshots/$(ECHO_END)
	$(ECHO_NOTHING)rm -rf build docs/undocumented.json$(ECHO_END)

sdk: stage
	$(ECHO_BEGIN)$(PRINT_FORMAT_MAKING) "Generating SDK"$(ECHO_END)
	$(ECHO_NOTHING)rm -rf $(ALDERIS_SDK_DIR) $(notdir $(ALDERIS_SDK_DIR)).zip$(ECHO_END)
	$(ECHO_NOTHING)for i in Alderis; do \
		mkdir -p $(ALDERIS_SDK_DIR)/$$i.framework; \
		cp -ra $(THEOS_STAGING_DIR)/Library/Frameworks/$$i.framework/{$$i,Headers,Modules} $(ALDERIS_SDK_DIR)/$$i.framework/; \
		tbd -p -v1 --ignore-missing-exports \
			--replace-install-name /Library/Frameworks/$$i.framework/$$i \
			$(ALDERIS_SDK_DIR)/$$i.framework/$$i \
			-o $(ALDERIS_SDK_DIR)/$$i.framework/$$i.tbd; \
		rm $(ALDERIS_SDK_DIR)/$$i.framework/$$i; \
		rm -rf $(THEOS_VENDOR_LIBRARY_PATH)/$$i.framework; \
	done$(ECHO_END)
	$(ECHO_NOTHING)rm -r $(THEOS_STAGING_DIR)/Library/Frameworks/*.framework/{Headers,Modules}$(ECHO_END)
	$(ECHO_NOTHING)cp -ra $(ALDERIS_SDK_DIR)/* $(THEOS_VENDOR_LIBRARY_PATH)$(ECHO_END)
	$(ECHO_NOTHING)printf 'This is an SDK for developers wanting to use Alderis.\n\nVersion: %s\n\nFor more information, visit %s.' \
		"$(THEOS_PACKAGE_BASE_VERSION)" \
		"https://hbang.github.io/Alderis/" \
		> $(ALDERIS_SDK_DIR)/README.txt$(ECHO_END)
	$(ECHO_NOTHING)cd $(dir $(ALDERIS_SDK_DIR)); \
		zip -9Xrq "$(THEOS_PROJECT_DIR)/$(notdir $(ALDERIS_SDK_DIR)).zip" $(notdir $(ALDERIS_SDK_DIR))$(ECHO_END)

ifeq ($(FINALPACKAGE),1)
before-package:: sdk
endif

.PHONY: docs sdk
