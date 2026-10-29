PROJECT := everline.xcodeproj
SCHEME := everline
DESTINATION := platform=macOS
DERIVED_DATA := build
VERSION ?= 0.0.0
BUILD ?= 1

.PHONY: test package clean

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)'

# Unsigned (ad-hoc) Release build zipped for a GitHub Release: make package VERSION=0.0.1 BUILD=42
package:
	@echo '$(VERSION)' | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' || { echo 'VERSION must be MAJOR.MINOR.PATCH, got "$(VERSION)"'; exit 1; }
	rm -rf $(DERIVED_DATA) dist
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA) \
		MARKETING_VERSION=$(VERSION) CURRENT_PROJECT_VERSION=$(BUILD) \
		CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
	mkdir -p dist
	ditto -c -k --keepParent $(DERIVED_DATA)/Build/Products/Release/$(SCHEME).app dist/Everline-$(VERSION).zip

clean:
	rm -rf $(DERIVED_DATA) dist
