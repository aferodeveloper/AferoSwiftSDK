#
# Makefile to build iOS Tokui app
#

-include local_config.mk

DATE ?= $(shell date "+%Y%m%d_%H%M%S")
DEST_PATH := $(shell pwd)

REVISION :=$(shell git log --pretty=format:'' | wc -l | sed 's/\ //g')

REVERT := git checkout
GIT_SHA1 := $(shell git log -1 --pretty=format:'%h')
NUM_CPUS := $(shell sysctl hw.ncpu | awk '{print $$2}')

CRASHLYTICS_SUBMIT := "Pods/Crashlytics/iOS/Crashlytics.framework/submit"
CRASHLYTICS_UPLOAD_DSYMS := "Pods/Fabric/upload-symbols"

# obtained from https://www.crashlytics.com/settings/organizations

# Afero's Crashlytics details
AFERO_API_KEY := 641fd144571e871d350c4243168feeb1a02157a5
AFERO_BUILD_SECRET := cfc9d3ae088713d6e6d0af05361fecdf0565578835f928f5f2b12bfb8c3f4d76
AFERO_SUBMIT_GROUPS := kiban-all

PLIST       ?= /usr/libexec/PlistBuddy
PLIST_GET   ?= $(shell $(PLIST) -c "Print $(1)" "$(2)")
PLIST_SET   ?= $(PLIST) -c "Set $(1) $(2)" "$(3)"
PLIST_RM    ?= $(PLIST) -c "Delete $(1)" "$(2)"

FASTLANE    ?= /usr/local/bin/fastlane
POD         ?= /usr/local/bin/pod
GEM         ?= /usr/local/bin/gem
BUNDLE      ?= /usr/local/bin/bundle
BREW        ?= /usr/local/bin/brew
RUBY        ?= /usr/local/bin/ruby
CARTHAGE    ?= /usr/local/bin/carthage

BUILD_RESULTS = $(DEST_PATH)/build
ARTIFACT_RESULTS = $(DEST_PATH)/artifacts

XCODE_WORKSPACE ?= iTokui.xcworkspace

ASSETS_REPO_URL := git@github.com:KibanLabsInc/tokui-assets.git
ASSETS_REPO_FILE ?= ../tokui-assets
ASSETS_PROJECT_FOLDER := iTokui/Assets

# Afero AppStore Config - sign with Afero
XCODE_SCHEME                := iTokui
PRODUCT_NAME                := Afero
APP_INFO                    := "iTokui/iTokui-Info.plist"
BUILD_SIGNED_BY             := "iPhone Distribution: Afero, Inc. (534JTUC87X)"
BUILD_OPTIONS_ADHOC         := Provisioning/TokuiAdHoc.plist
BUILD_OPTIONS_APPSTORE      := Provisioning/TokuiStore.plist
APP_GROUP_ID                := $(call PLIST_GET,KIAppGroupKey,$(APP_INFO))
APP_BUNDLE_ID				:= $(call PLIST_GET,CFBundleIdentifier,$(APP_INFO))
BUILD_TEAM_ID               := "534JTUC87X"
BUILD_TEAM_NAME             := "Afero, Inc"
APP_ZIP_NAME 				:= $(PRODUCT_NAME)_$(DATE)_$(REVISION)_$(GIT_SHA1)
APP_ZIP_STORE_NAME 			:= $(PRODUCT_NAME)_store_$(DATE)_$(REVISION)_$(GIT_SHA1)

# Afero Enterprise Build Config - sign with Afero
ENT_XCODE_SCHEME            := iTokuiEnt
ENT_PRODUCT_NAME            := Afero_Internal
ENT_APP_INFO                := "iTokui/iTokuiEnt-Info.plist"
ENT_BUILD_SIGNED_BY         := "iPhone Distribution: Kiban Labs, Inc"
ENT_BUILD_OPTIONS           := Provisioning/TokuiEnterprise.plist
ENT_APP_GROUP_ID            := $(call PLIST_GET,KIAppGroupKey,$(ENT_APP_INFO))
ENT_APP_BUNDLE_ID			:= $(call PLIST_GET,CFBundleIdentifier,$(ENT_APP_INFO))
ENT_BUILD_TEAM_ID           := "YVKN778Q2B"
ENT_BUILD_TEAM_NAME         := "Kiban Labs, Inc"
APP_ZIP_ENTERPRISE_NAME 	:= $(ENT_PRODUCT_NAME)_enterprise_$(DATE)_$(REVISION)_$(GIT_SHA1)
APP_ZIP_SIMULATOR_NAME 		:= $(ENT_PRODUCT_NAME)_simulator_$(DATE)_$(REVISION)_$(GIT_SHA1)

# Kenmore AppStore Config  - sign with Afero
AF_KEN_XCODE_SCHEME            := iTokuiKenmore
AF_KEN_PRODUCT_NAME            := Kenmore
AF_KEN_APP_INFO                := "iTokui/iTokuiKenmore-Info.plist"
AF_KEN_BUILD_SIGNED_BY         := "iPhone Distribution: Afero, Inc. (534JTUC87X)"
AF_KEN_BUILD_OPTIONS_APPSTORE  := Provisioning/TokuiStore.plist
AF_KEN_APP_GROUP_ID            := $(call PLIST_GET,KIAppGroupKey,$(AF_KEN_APP_INFO))
AF_KEN_APP_BUNDLE_ID		   := $(call PLIST_GET,CFBundleIdentifier,$(AF_KEN_APP_INFO))
AF_KEN_BUILD_TEAM_ID           := "534JTUC87X"
AF_KEN_BUILD_TEAM_NAME         := "Afero, Inc"
AF_KEN_APP_ZIP_NAME 		   := $(AF_KEN_PRODUCT_NAME)_$(DATE)_$(REVISION)_$(GIT_SHA1)
AF_KEN_APP_ZIP_STORE_NAME 	   := $(AF_KEN_PRODUCT_NAME)_store_$(DATE)_$(REVISION)_$(GIT_SHA1)

# Kenmore AppStore Config  - sign with Kenmore
KENMORE_API_KEY := 12b00e8c113e96228a9af8fa660fddb5885c1627
KENMORE_BUILD_SECRET := ee8c3eb4ea874bd0cfa1adb0bd959da2fa9bdef63cffdc7a63e1c50ea7221013

KEN_XCODE_SCHEME        	:= iTokuiKenmoreDeploy
KEN_PRODUCT_NAME            := KenmoreDeploy
KEN_APP_INFO                := "iTokui/iTokuiKenmoreDeploy-Info.plist"
KEN_BUILD_SIGNED_BY         := "iPhone Distribution: Sears Brands Management Corporation (6Z25T829A5)"
KEN_BUILD_OPTIONS_APPSTORE  := Provisioning/TokuiKenmoreStore.plist
KEN_APP_BUNDLE_ID			:= $(call PLIST_GET,CFBundleIdentifier,$(KEN_APP_INFO))
KEN_BUILD_TEAM_ID           := "6Z25T829A5"
KEN_BUILD_TEAM_NAME         := "Sears Brands Management Corporation"
KEN_APP_ZIP_NAME 			:= $(KEN_PRODUCT_NAME)_$(DATE)_$(REVISION)_$(GIT_SHA1)
KEN_APP_ZIP_STORE_NAME 		:= $(KEN_PRODUCT_NAME)_store_$(DATE)_$(REVISION)_$(GIT_SHA1)

# Kenmore Enterprise Build Config
ENT_KEN_XCODE_SCHEME        := iTokuiKenmoreEnt
ENT_KEN_PRODUCT_NAME        := Afero_Kenmore_Internal
ENT_KEN_APP_INFO            := "iTokui/iTokuiKenmoreEnt-Info.plist"
ENT_KEN_BUILD_SIGNED_BY     := "iPhone Distribution: Kiban Labs, Inc"
ENT_KEN_BUILD_OPTIONS       := Provisioning/TokuiEnterprise.plist
ENT_KEN_APP_GROUP_ID        := $(call PLIST_GET,KIAppGroupKey,$(ENT_KEN_APP_INFO))
ENT_KEN_APP_BUNDLE_ID		:= $(call PLIST_GET,CFBundleIdentifier,$(ENT_KEN_APP_INFO))
ENT_KEN_BUILD_TEAM_ID       := "YVKN778Q2B"
ENT_KEN_BUILD_TEAM_NAME     := "Kiban Labs, Inc"
APP_ZIP_KENMORE_ENTERPRISE_NAME := $(ENT_KEN_PRODUCT_NAME)_enterprise_$(DATE)_$(REVISION)_$(GIT_SHA1)

PRODUCT_ARCHIVE_FOLDER      = iTokui.xcarchive
PRODUCT_ARCHIVE             = $(BUILD_RESULTS)/$(PRODUCT_ARCHIVE_FOLDER)

APP_SETTINGS_RESOURCE 		:= "iTokui/Resources/Settings.bundle/Root.plist"

all:
	@echo "Targets:"
	@echo "  bootstrap - install tools, pods, fresh"
	@echo "  clean-super - clean code, sango assets and artifacts"
	@echo "  clean - clean just code project"
	@echo "  version - show next build number"
	@echo "  adhoc-package - build and sign an ad hoc build for afero"
	@echo "  appstore-package - build and sign an app store build for afero"
	@echo "  enterprise-package - build and sign enterprise build for afero"
	@echo "  kenmore-appstore-package - build and sign an app store build for kenmore"
	@echo "  kenmore-appstore-deploy - build and sign an app store build with kenmore keys"
	@echo "  kenmore-enterprise-package - build and sign kenmore enterprise build for kenmore"
	@echo "  sim-package - build simulator for iPhone 6s"
	@echo "  test_kiban_simulator - perform Kiban unit tests on simulator iPhone 6s"
	@echo "  artifacts - build artifacts for adhoc-package, appstore-package, enterprise-package"
	@echo "  update_dev_assets - use sango to compile dev assets for afero"
	@echo "  update_prod_assets - use sango to compile prod assets for afero"
	@echo "  update_dev_kenmore_assets - use sango to compile dev assets for kenmore"
	@echo "  update_prod_kenmore_assets - use sango to compile prod assets for kenmore"
	@echo "  update_en_locale - walk through source, and generate strings file in asset depot"

# this is here so that our default 'all' is called with no parameters
include sango.mk

version:
	@echo "Current build version: $(REVISION) sha1 $(GIT_SHA1)"

# ===========================================
# high-level package targets

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

_disable_crashlytics:
	@rm -f USE_CRASHLYTICS

_enable_crashlytics:
	@echo "Enable Crashlytics"
	@echo "1" >USE_CRASHLYTICS

_reverts:
	@$(REVERT) $(APP_INFO)
	@$(REVERT) $(ENT_APP_INFO)
	@$(REVERT) $(KEN_APP_INFO)
	@$(REVERT) $(AF_KEN_APP_INFO)
	@$(REVERT) $(ENT_KEN_APP_INFO)
	@$(REVERT) $(APP_SETTINGS_RESOURCE)

# Set the plist revsion bundle of the app
# requires FILE to be set
FILE :=
_set_bundle:
	$(call PLIST_SET,CFBundleVersion,$(REVISION),$(FILE))

# removes the first entry in the Root.plist which contain the developer options for app
remove_developer_settings:
	$(REVERT) $(APP_SETTINGS_RESOURCE)
	$(call PLIST_RM,:PreferenceSpecifiers:0,$(APP_SETTINGS_RESOURCE))

# http://www.mokacoding.com/blog/xcodebuild-destination-options/
# Builds the afero ad hoc, store scheme/target
_build_appstore: _pod_installed
	@$(MAKE) _set_bundle FILE=$(APP_INFO)
	@echo "Build Ad Hoc/Store Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				archive \
				-archivePath $(PRODUCT_ARCHIVE) \
				-configuration Release \
				-destination 'generic/platform=iOS'

# Builds the afero enterprise, scheme/target
_build_enterprise: _pod_installed
	@$(MAKE) _set_bundle FILE=$(ENT_APP_INFO)
	@echo "Build Enterprise Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(ENT_XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				archive \
				-archivePath $(PRODUCT_ARCHIVE) \
				-configuration Release \
				-destination 'generic/platform=iOS'

# Builds the kenmore ad hoc, store scheme/target
_build_kenmore_appstore: _pod_installed
	@$(MAKE) _set_bundle FILE=$(AF_KEN_APP_INFO)
	@echo "Build Kenmore Ad Hoc/Store Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(AF_KEN_XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				archive \
				-archivePath $(PRODUCT_ARCHIVE) \
				-configuration Release \
				-destination 'generic/platform=iOS'

_build_kenmore_appstore_deploy: _pod_installed
	@$(MAKE) _set_bundle FILE=$(KEN_APP_INFO)
	@echo "Build Kenmore Ad Hoc/Store Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(KEN_XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				archive \
				-archivePath $(PRODUCT_ARCHIVE) \
				-configuration Release \
				-destination 'generic/platform=iOS'

# Builds the kenmore enterprise, scheme/target
_build_kenmore_enterprise: _pod_installed
	@$(MAKE) _set_bundle FILE=$(ENT_KEN_APP_INFO)
	@echo "Build Enterprise Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(ENT_KEN_XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				archive \
				-archivePath $(PRODUCT_ARCHIVE) \
				-configuration Release \
				-destination 'generic/platform=iOS'
	
test_kiban_simulator: _pod_installed
	@$(MAKE) _set_bundle FILE=$(APP_INFO)
	@echo "Test Kiban Simulator"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				test \
				-configuration Debug \
				-destination 'platform=iOS Simulator,name=iPhone 6s' \
				CONFIGURATION_BUILD_DIR=$(BUILD_RESULTS) \
				SYMROOT=$(BUILD_RESULTS)

_build_simulator: _pod_installed
	@$(MAKE) _set_bundle FILE=$(APP_INFO)
	@echo "Build Simulator Scheme"
	xcodebuild -workspace $(XCODE_WORKSPACE) \
				-scheme $(ENT_XCODE_SCHEME) \
				-verbose \
				-jobs $(NUM_CPUS) \
				build \
				-configuration Debug \
				-destination 'platform=iOS Simulator,name=iPhone 6s' \
				CONFIGURATION_BUILD_DIR=$(BUILD_RESULTS) \
				SYMROOT=$(BUILD_RESULTS)

# this is used to package the IPA from the archive.
# Target build must be run first
# requires ARCHIVE, BUILD_OPTIONS, SIGNED_OPTION and BUILD_OUTPUT to be set
BUILD_OPTIONS :=
SIGNED_OPTION :=
BUILD_OUTPUT :=
ARCHIVE := 
_export_build:
	xcodebuild -exportArchive \
				-exportOptionsPlist "$(BUILD_OPTIONS)" \
				-archivePath "$(ARCHIVE)" \
				-exportPath "$(BUILD_OUTPUT)" \
				CODE_SIGN_IDENTITY="$(SIGNED_OPTION)"

CL_KEY :=
_upload_dsyms:
	find $(PRODUCT_ARCHIVE)/dSYMs -name "*.dSYM" | xargs -I \{\} $(CRASHLYTICS_UPLOAD_DSYMS) -d -a $(CL_KEY) -p ios \{\}

ARCHIVE :=
IPA :=
CL_KEY :=
CL_SECRET :=
CL_GROUP :=
_submit_crashlytics:
	@rm -f temp_notes.txt
	@echo "----"  >temp_notes.txt
	@echo "Changes:" >>temp_notes.txt
	@echo "----"  >>temp_notes.txt
	@git log --oneline --no-merges --since yesterday >>temp_notes.txt
	@echo "Submitting to Crashlytics..."
	@env ARCHIVE_PRODUCTS_PATH=$(ARCHIVE)/Products; \
		env ARCHIVE_DSYMS_PATH=$(ARCHIVE)/dSYMs; \
		./$(CRASHLYTICS_SUBMIT) \
			$(CL_KEY) $(CL_SECRET) \
			-ipaPath $(IPA) \
			-notesPath temp_notes.txt \
			-groupAliases $(CL_GROUP) \
			-notifications YES \
			-debug YES;
	@echo "Done!"
	@rm -f temp_notes.txt

# set FASTLANE_PASSWORD for password
# set FASTLANE_USER for user
IPA :=
APP_ID :=
_submit_testflight: guard-FASTLANE_PASSWORD guard-FASTLANE_USER
	$(FASTLANE) pilot upload --ipa $(IPA) \
							 --team_id $(BUILD_TEAM_ID) \
							 --team_name $(BUILD_TEAM_NAME) \
							 --app_identifier $(APP_ID) \
							 --wait_processing_interval 1 \
							 --skip_submission false \
							 --skip_waiting_for_build_processing true \
							 --verbose

# AdHoc build
.PHONY: adhoc-package
adhoc-package: _klean remove_developer_settings _build_appstore
	@echo "Signing for AdHoc $(APP_ZIP_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(BUILD_OPTIONS_ADHOC) \
			SIGNED_OPTION=$(BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
	mv $(BUILD_RESULTS)/$(PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(APP_ZIP_NAME).ipa
	@cd $(PRODUCT_ARCHIVE)/dSYMs; zip -q -r -y -9 -v ../../$(APP_ZIP_NAME)_dSYM.zip * -x .DS_Store
	@$(MAKE) _reverts

# Afero AppStore build
.PHONY: appstore-package
appstore-package: _fastlane_installed _klean remove_developer_settings _build_appstore
	@echo "Signing for Store $(APP_ZIP_STORE_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(BUILD_OPTIONS_APPSTORE) \
			SIGNED_OPTION=$(BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
ifdef DEPLOY_TF
	$(MAKE) _submit_testflight IPA=$(BUILD_RESULTS)/$(PRODUCT_NAME).ipa \
			APP_ID=$(APP_BUNDLE_ID) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
	@$(MAKE) _upload_dsyms CL_KEY=$(AFERO_API_KEY)
endif
	mv $(BUILD_RESULTS)/$(PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(APP_ZIP_STORE_NAME).ipa
	cd $(PRODUCT_ARCHIVE)/dSYMs; zip -q -r -y -9 ../../$(APP_ZIP_STORE_NAME)_dSYM.zip * -x .DS_Store
	@$(MAKE) _reverts

# Afero Enterprise build
# pass DEPLOY_CL=1 to deploy to crashlytics
.PHONY: enterprise-package
enterprise-package: _klean _build_enterprise
	@echo "Signing for Enterprise $(APP_ZIP_ENTERPRISE_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(ENT_BUILD_OPTIONS) \
			SIGNED_OPTION=$(ENT_BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
ifdef DEPLOY_CL
	$(MAKE) _submit_crashlytics IPA=$(BUILD_RESULTS)/$(ENT_PRODUCT_NAME).ipa \
			ARCHIVE=$(PRODUCT_ARCHIVE) \
			CL_KEY=$(AFERO_API_KEY) \
			CL_SECRET=$(AFERO_BUILD_SECRET) \
			CL_GROUP=$(AFERO_SUBMIT_GROUPS)
	@$(MAKE) _upload_dsyms CL_KEY=$(AFERO_API_KEY)
endif
	mv $(BUILD_RESULTS)/$(ENT_PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(APP_ZIP_ENTERPRISE_NAME).ipa
	cd $(PRODUCT_ARCHIVE)/dSYMs; zip -q -r -y -9 ../../$(APP_ZIP_ENTERPRISE_NAME)_dSYM.zip * -x .DS_Store
	@$(MAKE) _reverts	

# Kenmore AppStore build - afero signed
.PHONY: kenmore-appstore-package
kenmore-appstore-package: _fastlane_installed _klean remove_developer_settings _build_kenmore_appstore
	@echo "Signing for Store $(AF_KEN_APP_ZIP_STORE_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(AF_KEN_BUILD_OPTIONS_APPSTORE) \
			SIGNED_OPTION=$(AF_KEN_BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
ifdef DEPLOY_TF
	$(MAKE) _submit_testflight IPA=$(BUILD_RESULTS)/$(AF_KEN_PRODUCT_NAME).ipa \
			APP_ID=$(AF_KEN_APP_BUNDLE_ID) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
	@$(MAKE) _upload_dsyms CL_KEY=$(KENMORE_API_KEY)
endif
	mv $(BUILD_RESULTS)/$(AF_KEN_PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(AF_KEN_APP_ZIP_STORE_NAME).ipa
	cd $(PRODUCT_ARCHIVE)/dSYMs; zip -q -r -y -9 ../../$(AF_KEN_APP_ZIP_STORE_NAME)_dSYM.zip * -x .DS_Store
	@$(MAKE) _reverts

# Kenmore AppStore build - kenmore signed
.PHONY: kenmore-appstore-deploy
kenmore-appstore-deploy: _fastlane_installed _klean remove_developer_settings _build_kenmore_appstore_deploy
	@echo "Signing for Store $(KEN_APP_ZIP_STORE_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(KEN_BUILD_OPTIONS_APPSTORE) \
			SIGNED_OPTION=$(KEN_BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
ifdef DEPLOY_TF
	$(MAKE) _submit_testflight IPA=$(BUILD_RESULTS)/$(KEN_PRODUCT_NAME).ipa \
			APP_ID=$(KEN_APP_BUNDLE_ID) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
	@$(MAKE) _upload_dsyms CL_KEY=$(KENMORE_API_KEY)
endif
	mv $(BUILD_RESULTS)/$(KEN_PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(KEN_APP_ZIP_STORE_NAME).ipa
	cd $(BUILD_RESULTS); zip -q -r -y -9 $(KEN_APP_ZIP_STORE_NAME)_Archive.zip $(PRODUCT_ARCHIVE_FOLDER) -x .DS_Store
	@$(MAKE) _reverts

# Kenmore Enterprise build
kenmore-enterprise-package: _klean _build_kenmore_enterprise
	@echo "Signing for Kenmore Enterprise $(APP_ZIP_KENMORE_ENTERPRISE_NAME)..."
	$(MAKE) _export_build BUILD_OPTIONS=$(ENT_KEN_BUILD_OPTIONS) \
			SIGNED_OPTION=$(ENT_KEN_BUILD_SIGNED_BY) \
			BUILD_OUTPUT=$(BUILD_RESULTS) \
			ARCHIVE=$(PRODUCT_ARCHIVE)
ifdef DEPLOY_CL
	$(MAKE) _submit_crashlytics IPA=$(BUILD_RESULTS)/$(ENT_KEN_PRODUCT_NAME).ipa \
			ARCHIVE=$(PRODUCT_ARCHIVE) \
			CL_KEY=$(AFERO_API_KEY) \
			CL_SECRET=$(AFERO_BUILD_SECRET) \
			CL_GROUP=$(AFERO_SUBMIT_GROUPS)
	@$(MAKE) _upload_dsyms CL_KEY=$(AFERO_API_KEY)
endif
	mv $(BUILD_RESULTS)/$(ENT_KEN_PRODUCT_NAME).ipa $(BUILD_RESULTS)/$(APP_ZIP_KENMORE_ENTERPRISE_NAME).ipa
	cd $(PRODUCT_ARCHIVE)/dSYMs; zip -q -r -y -9 ../../$(APP_ZIP_KENMORE_ENTERPRISE_NAME)_dSYM.zip * -x .DS_Store
	@$(MAKE) _reverts	

# Simulator build
.PHONY: sim-package
sim-package: _klean _build_simulator
	@echo "Zipping $(APP_ZIP_SIMULATOR_NAME)... Simulator"
	cd $(BUILD_RESULTS); zip -q -r -y -9 $(APP_ZIP_SIMULATOR_NAME)_iphone_6s.zip * -x .DS_Store
	@$(MAKE) _reverts

# build artifacts for adhoc-package, appstore-package, enterprise-package
# pass DEPLOY_CL=1 to deploy to crashlytics
# pass DEPLOY_TF=1 to deploy to testflight
.PHONY: artifacts
artifacts:
	@rm -rdf $(ARTIFACT_RESULTS)
	@mkdir -p $(ARTIFACT_RESULTS)
	# @$(MAKE) adhoc-package DATE=$(DATE)
	# @cp $(BUILD_RESULTS)/*.ipa $(ARTIFACT_RESULTS)/.
	# @cp $(BUILD_RESULTS)/*.zip $(ARTIFACT_RESULTS)/.
	@$(MAKE) enterprise-package DATE=$(DATE) DEPLOY_CL=$(DEPLOY_CL)
	@cp $(BUILD_RESULTS)/*.ipa $(ARTIFACT_RESULTS)/.
	@cp $(BUILD_RESULTS)/*.zip $(ARTIFACT_RESULTS)/.
	@$(MAKE) appstore-package DATE=$(DATE) DEPLOY_TF=$(DEPLOY_TF)
	@cp $(BUILD_RESULTS)/*.ipa $(ARTIFACT_RESULTS)/.
	@cp $(BUILD_RESULTS)/*.zip $(ARTIFACT_RESULTS)/.
	# @$(MAKE) sim-package DATE=$(DATE)
	# @cp $(BUILD_RESULTS)/*.zip $(ARTIFACT_RESULTS)/.

$(ARTIFACT_RESULTS):
	mkdir -p "$@"

$(BUILD_RESULT):
	mkdir -p "$@"

_klean: _disable_crashlytics _reverts
	@echo "Cleaning..."
	@rm -rdf $(BUILD_RESULTS)
	@rm -f *.zip
	@if [ -a $(XCODE_WORKSPACE)/contents.xcworkspacedata ]; then \
		echo "Clean Xcode"; \
		xcodebuild -workspace $(XCODE_WORKSPACE) -scheme $(XCODE_SCHEME) clean &>/dev/null; \
	fi;

clean-super: _klean
	@rm -rdf $(ASSETS_REPO_FILE)
	@rm -rdf Carthage/Build/*
	@rm -rdf $(ARTIFACT_RESULTS)
	@rm -rdf DerivedData
	@echo "Done!"

clean: _klean
	@echo "Done!"

# check to see if fastlane is installed
_fastlane_installed:
	@if ! [ -a $(FASTLANE) ]; then \
		echo "fastlane needs to be installed, perform bootstrap target"; \
	fi;

# check to see if cocoapods is installed globally
_pod_installed:
	@if ! [ -a $(POD) ]; then \
		echo "cocoapods needs to be installed, perform bootstrap target"; \
	fi;

.PHONY: _pod_update
_pod_update:
ifndef IGNORE_POD
	@if ! [ -d Pods ]; then \
		$(POD) repo update && $(POD) install; \
	else \
		$(POD) repo update && $(POD) update; \
	fi;
endif

# check to see if our asset repo is cloned, if not clone it
_assets_installed:
	@if ! [ -d $(ASSETS_REPO_FILE) ]; then \
		git clone $(ASSETS_REPO_URL) $(ASSETS_REPO_FILE); \
	fi;

# Set ASSETS_TAG from the command line to a number, from the sango repro to restrict to a specific build tag
RESTRICT_TAG := 
ifdef ASSETS_TAG
	RESTRICT_TAG := -input_assets_tag $(ASSETS_TAG)
endif

update_dev_assets: _sango_installed _assets_installed
	@rm -rdf $(ASSETS_PROJECT_FOLDER)
	$(SANGO) $(SANGO_OPTS) -config config_assets_dev.json -input_assets $(ASSETS_REPO_FILE) $(RESTRICT_TAG)

update_prod_assets: _sango_installed _assets_installed
	@rm -rdf $(ASSETS_PROJECT_FOLDER)
	$(SANGO) $(SANGO_OPTS) -config config_assets_prod.json -input_assets $(ASSETS_REPO_FILE) $(RESTRICT_TAG)

update_dev_kenmore_assets: _sango_installed _assets_installed
	@rm -rdf $(ASSETS_PROJECT_FOLDER)
	$(SANGO) $(SANGO_OPTS) -config config_kenmore_assets_dev.json -input_assets $(ASSETS_REPO_FILE) $(RESTRICT_TAG)

update_prod_kenmore_assets: _sango_installed _assets_installed
	@rm -rdf $(ASSETS_PROJECT_FOLDER)
	$(SANGO) $(SANGO_OPTS) -config config_kenmore_assets_prod.json -input_assets $(ASSETS_REPO_FILE) $(RESTRICT_TAG)

update_en_locale: _sango_installed _assets_installed
	@rm -f $(ASSETS_REPO_FILE)/locale/ios/en.strings
	@find iTokui -name "*.swift" | xargs genstrings -q -u -o $(ASSETS_REPO_FILE)/locale/ios
	@iconv -f utf-16 -t utf-8 $(ASSETS_REPO_FILE)/locale/ios/Localizable.strings > $(ASSETS_REPO_FILE)/locale/ios/en.strings
	@rm $(ASSETS_REPO_FILE)/locale/ios/Localizable.strings
	@$(SANGO) $(SANGO_OPTS) -locale_only -config config_assets_dev.json -input_assets $(ASSETS_REPO_FILE)

3rd-party-install : cart-install pod-update

pod-%:
	$(POD) $*

# =============================================
# Used for non-Pod (Framework) prerequisites

# Note that we're restricting to iOS and Mac for now, as the WatchOS
# builds are currently in flux. Once this has been sorted by the Nimble/RAC/Carthage
# teams, "WatchOS" should be able to be appended to CARTHAGE_PLATFORMS.
# Also note that as of this writing, explicit platform settings seem to be
# required (https://github.com/ReactiveCocoa/ReactiveCocoa/issues/2319).

CARTHAGE_PLATFORMS := iOS Mac

cart-install: $(CARTHAGE)
	$(CARTHAGE) update --no-build
	@for p in $(CARTHAGE_PLATFORMS); do \
		echo "Carthage build for platform $$p..."; \
		$(CARTHAGE) build --platform $$p; \
	done

# =============================================
# Android external dir (for shared fixtures)

git-externals:
	git external init
	git external update


# =============================================
# Bootstrap targets
# These are just convenience for setting up the environment.

bootstrap:
	@if [ -a $(BREW) ]; then \
		$(BREW) update; \
	else \
		/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; \
	fi;
	$(BREW) install ruby
	$(BREW) install carthage
	$(GEM) install bundler
	$(BUNDLE) update
	$(POD) update

FORCE:

.PHONY: bootstrap all clean


