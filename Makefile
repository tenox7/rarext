-include .env

APP_PATH = build/Build/Products/Release/RARExt.app
APPEX_PATH = $(APP_PATH)/Contents/PlugIns/RAR.appex
PKG_ROOT = build/pkg-root
SCRIPTS_DIR = build/pkg-scripts
PKG_OUTPUT = build/RARExt.pkg

.PHONY: build sign pkg release install clean

build:
	xcodebuild -workspace RARExt.xcworkspace -scheme RARExt -configuration Release -derivedDataPath build clean build

pkg: build
	rm -rf $(PKG_ROOT) $(SCRIPTS_DIR)
	mkdir -p $(PKG_ROOT)/Applications $(SCRIPTS_DIR)
	cp -R $(APP_PATH) $(PKG_ROOT)/Applications/
	cp scripts/postinstall $(SCRIPTS_DIR)/
	chmod +x $(SCRIPTS_DIR)/postinstall
	pkgbuild --root $(PKG_ROOT) --scripts $(SCRIPTS_DIR) --identifier com.github.tenox7.rarext --version 1.0 --install-location / $(PKG_OUTPUT)
	@echo ""
	@echo "Package created: $(PKG_OUTPUT)"
	@echo "Double-click the .pkg to install or run: sudo installer -pkg $(PKG_OUTPUT) -target /"

sign: build
	@test -n "$(DEV_ID_APP)" || { echo "DEV_ID_APP not set — copy .env.example to .env and fill in"; exit 1; }
	codesign --force --options runtime --timestamp \
		--entitlements RARAction/RARAction.entitlements \
		--sign "$(DEV_ID_APP)" $(APPEX_PATH)
	codesign --force --options runtime --timestamp \
		--sign "$(DEV_ID_APP)" $(APP_PATH)

release: sign
	@test -n "$(DEV_ID_INSTALLER)" || { echo "DEV_ID_INSTALLER not set — copy .env.example to .env and fill in"; exit 1; }
	@test -n "$(NOTARY_PROFILE)" || { echo "NOTARY_PROFILE not set — copy .env.example to .env and fill in"; exit 1; }
	rm -rf $(PKG_ROOT) $(SCRIPTS_DIR)
	mkdir -p $(PKG_ROOT)/Applications $(SCRIPTS_DIR)
	cp -R $(APP_PATH) $(PKG_ROOT)/Applications/
	cp scripts/postinstall $(SCRIPTS_DIR)/
	chmod +x $(SCRIPTS_DIR)/postinstall
	pkgbuild --root $(PKG_ROOT) --scripts $(SCRIPTS_DIR) \
		--identifier com.github.tenox7.rarext --version 1.0 --install-location / \
		--sign "$(DEV_ID_INSTALLER)" --timestamp $(PKG_OUTPUT)
	xcrun notarytool submit $(PKG_OUTPUT) --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple $(PKG_OUTPUT)
	@echo ""
	@echo "Signed + notarized: $(PKG_OUTPUT)"

install: build
	killall RARExt 2>/dev/null || true
	rm -rf /Applications/RARExt.app
	cp -R $(APP_PATH) /Applications/RARExt.app
	open -a /Applications/RARExt.app

clean:
	rm -rf build
