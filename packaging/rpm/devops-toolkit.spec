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

# Copy source files used by the launcher
cp -r * %{buildroot}/opt/devops-toolkit/ 2>/dev/null || true

%files
/opt/devops-toolkit/
%doc README.md

%post
# Create symlinks
ln -sf /opt/devops-toolkit/devops-toolkit.sh %{_bindir}/devops
ln -sf /opt/devops-toolkit/Redes/ssh-manager.sh %{_bindir}/ssh-manager
ln -sf /opt/devops-toolkit/Redes/port-checker.sh %{_bindir}/port-checker
ln -sf /opt/devops-toolkit/Services/service-manager.sh %{_bindir}/service-manager
ln -sf /opt/devops-toolkit/Storage/storage-manager.sh %{_bindir}/storage-manager
ln -sf /opt/devops-toolkit/Storage/mount-manager.sh %{_bindir}/mount-manager

ln -sf /opt/devops-toolkit/django-project-creator-v3.sh %{_bindir}/django-creator
ln -sf /opt/devops-toolkit/PHP/php-switcher.sh %{_bindir}/php-switcher
ln -sf /opt/devops-toolkit/Redes/download-manager.sh %{_bindir}/download-manager
ln -sf /opt/devops-toolkit/laravel-start.sh %{_bindir}/laravel-start
ln -sf /opt/devops-toolkit/Redes/quick-dns-fix.sh %{_bindir}/dns-fix
ln -sf /opt/devops-toolkit/Python/python-project-manager.sh %{_bindir}/python-project-manager

find /opt/devops-toolkit -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo "DevOps Toolkit installed successfully!"

%preun
# Remove symlinks
rm -f %{_bindir}/devops
rm -f %{_bindir}/ssh-manager
rm -f %{_bindir}/port-checker
rm -f %{_bindir}/service-manager
rm -f %{_bindir}/storage-manager
rm -f %{_bindir}/mount-manager
rm -f %{_bindir}/django-creator
rm -f %{_bindir}/php-switcher
rm -f %{_bindir}/download-manager
rm -f %{_bindir}/laravel-start
rm -f %{_bindir}/dns-fix
rm -f %{_bindir}/python-project-manager

%changelog
* Fri Jan 03 2025 John Sabba <johnsabba@example.com> - 1.0.0-1
- Initial RPM package release
- Django project creator with templates
- PHP version switcher
- Network and storage management tools
