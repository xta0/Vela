PROJECT ?= Vela.xcodeproj
SCHEME ?= Vela
DESTINATION ?= platform=macOS
DERIVED_DATA_PATH ?= /private/tmp/VelaDerivedData

.PHONY: test
test:
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		CODE_SIGNING_ALLOWED=NO \
		-only-testing:VelaTests
