APP_PATH = build/Build/Products/Release/RARExt.app
PKG_ROOT = build/pkg-root
SCRIPTS_DIR = build/pkg-scripts
PKG_OUTPUT = build/RARExt.pkg

.PHONY: build pkg install clean

build:
	xcodebuild -workspace RARExt.xcworkspace -scheme RARExt -configuration Release -derivedDataPath build clean build

pkg: build
	rm -rf $(PKG_ROOT) $(SCRIPTS_DIR)
	mkdir -p $(PKG_ROOT)/Applications $(SCRIPTS_DIR)
	cp -R $(APP_PATH) $(PKG_ROOT)/Applications/
	cp scripts/postinstall $(SCRIPTS_DIR)/
	chmod +x $(SCRIPTS_DIR)/postinstall
	pkgbuild --root $(PKG_ROOT) --scripts $(SCRIPTS_DIR) --identifier com.example.rarext --version 1.0 --install-location / $(PKG_OUTPUT)
	@echo ""
	@echo "Package created: $(PKG_OUTPUT)"
	@echo "Double-click the .pkg to install or run: sudo installer -pkg $(PKG_OUTPUT) -target /"

install: build
	killall RARExt 2>/dev/null || true
	rm -rf /Applications/RARExt.app
	cp -R $(APP_PATH) /Applications/RARExt.app
	open -a /Applications/RARExt.app

clean:
	rm -rf build
