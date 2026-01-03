Name:           devops-toolkit
Version:        1.1.0
Release:        1%{?dist}
Summary:        DevOps Toolkit - Collection of development and deployment scripts
License:        MIT
URL:            https://github.com/sabbajohn/useful-stuff
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  bash
Requires:       bash >= 4.0
Requires:       curl
Requires:       git
Requires:       python3
Requires:       php-cli

%description
A comprehensive collection of development scripts including:
- Django project creator with multiple templates  
- PHP version switcher
- Network troubleshooting tools
- Storage management utilities
- Download manager
- Laravel starter scripts

This toolkit helps developers and DevOps engineers automate common tasks
and streamline their development workflow.

%prep
%setup -q

%build
# Nothing to build

%install
mkdir -p %{buildroot}/opt/devops-toolkit
mkdir -p %{buildroot}%{_bindir}

# Copy source files
cp -r devops-toolkit/* %{buildroot}/opt/devops-toolkit/
cp -r Django %{buildroot}/opt/devops-toolkit/

%files
/opt/devops-toolkit/
%doc README.md

%post
# Create symlinks
ln -sf /opt/devops-toolkit/bin/scripts/django-project-creator-v3.sh %{_bindir}/django-creator
ln -sf /opt/devops-toolkit/bin/scripts/php-switcher.sh %{_bindir}/php-switcher  
ln -sf /opt/devops-toolkit/bin/scripts/download-manager.sh %{_bindir}/download-manager
ln -sf /opt/devops-toolkit/bin/scripts/laravel-start.sh %{_bindir}/laravel-start
ln -sf /opt/devops-toolkit/bin/scripts/mac-storage-manager.sh %{_bindir}/storage-manager
ln -sf /opt/devops-toolkit/bin/scripts/quick-dns-fix.sh %{_bindir}/dns-fix

chmod +x /opt/devops-toolkit/bin/scripts/*.sh

echo "DevOps Toolkit installed successfully!"

%preun
# Remove symlinks
rm -f %{_bindir}/django-creator
rm -f %{_bindir}/php-switcher
rm -f %{_bindir}/download-manager
rm -f %{_bindir}/laravel-start
rm -f %{_bindir}/storage-manager
rm -f %{_bindir}/dns-fix

%changelog
* Fri Jan 03 2025 John Sabba <johnsabba@example.com> - 1.0.0-1
- Initial RPM package release
- Django project creator with templates
- PHP version switcher
- Network and storage management tools