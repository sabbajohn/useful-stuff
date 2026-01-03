# DevOps Toolkit Makefile
# Builds packages for multiple distributions

VERSION := 1.1.0
PACKAGE_NAME := devops-toolkit
BUILD_DIR := build
DEB_DIR := $(BUILD_DIR)/debian
RPM_DIR := $(BUILD_DIR)/rpm

.PHONY: all clean deb rpm homebrew install test

all: clean deb rpm homebrew

# Clean build directory
clean:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)

# Build Debian package
deb: clean
	mkdir -p $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)
	
	# Copy source files
	cp -r devops-toolkit $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/
	cp -r Django $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/
	cp README.md $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/
	
	# Create debian control structure
	mkdir -p $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/debian
	cp packaging/debian/* $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/debian/
	
	# Set permissions
	chmod +x $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/debian/postinst
	chmod +x $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)/debian/prerm
	
	# Build package
	cd $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION) && dpkg-buildpackage -b -uc -us
	
	@echo "Debian package built: $(DEB_DIR)/$(PACKAGE_NAME)_$(VERSION)_all.deb"

# Build RPM package
rpm: clean
	mkdir -p $(RPM_DIR)/SOURCES
	mkdir -p $(RPM_DIR)/SPECS
	mkdir -p $(RPM_DIR)/BUILD
	mkdir -p $(RPM_DIR)/RPMS
	mkdir -p $(RPM_DIR)/SRPMS
	
	# Create source tarball
	tar -czf $(RPM_DIR)/SOURCES/$(PACKAGE_NAME)-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='build' \
		--exclude='*.deb' \
		--exclude='*.rpm' \
		.
	
	# Copy spec file
	cp packaging/rpm/$(PACKAGE_NAME).spec $(RPM_DIR)/SPECS/
	
	# Build RPM
	rpmbuild -ba $(RPM_DIR)/SPECS/$(PACKAGE_NAME).spec \
		--define "_topdir $(PWD)/$(RPM_DIR)"
	
	@echo "RPM package built in $(RPM_DIR)/RPMS/"

# Generate Homebrew formula
homebrew: 
	@echo "Generating Homebrew formula..."
	@sed 's/{{VERSION}}/$(VERSION)/g' packaging/homebrew/Formula/devops-toolkit.rb.template > \
		packaging/homebrew/Formula/devops-toolkit.rb
	@echo "Homebrew formula generated: packaging/homebrew/Formula/devops-toolkit.rb"

# Install locally for development
install:
	sudo mkdir -p /opt/devops-toolkit
	sudo cp -r devops-toolkit/* /opt/devops-toolkit/
	sudo cp -r Django /opt/devops-toolkit/
	sudo chmod +x /opt/devops-toolkit/bin/scripts/*.sh
	bash packaging/debian/postinst

# Uninstall local installation
uninstall:
	bash packaging/debian/prerm
	sudo rm -rf /opt/devops-toolkit

# Run tests
test:
	@echo "Running tests..."
	bash tests/test-scripts.sh

# Create release tarball
release: clean
	mkdir -p $(BUILD_DIR)/release
	tar -czf $(BUILD_DIR)/release/$(PACKAGE_NAME)-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='build' \
		--exclude='*.deb' \
		--exclude='*.rpm' \
		--exclude='.DS_Store' \
		.
	
	@echo "Release tarball created: $(BUILD_DIR)/release/$(PACKAGE_NAME)-$(VERSION).tar.gz"

# Build Docker image for testing
docker:
	docker build -t $(PACKAGE_NAME):$(VERSION) -f packaging/docker/Dockerfile .

# Show help
help:
	@echo "DevOps Toolkit Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Build all packages (deb, rpm, homebrew)"
	@echo "  deb         - Build Debian package"
	@echo "  rpm         - Build RPM package"
	@echo "  homebrew    - Generate Homebrew formula"
	@echo "  install     - Install locally for development"
	@echo "  uninstall   - Remove local installation"
	@echo "  test        - Run tests"
	@echo "  release     - Create release tarball"
	@echo "  docker      - Build Docker image"
	@echo "  clean       - Clean build directory"
	@echo "  help        - Show this help"