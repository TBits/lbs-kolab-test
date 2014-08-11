%if 0%{?opensuse_bs}
#!BuildIgnore   httpd
%endif

%if 0%{?suse_version}
%global httpd_group www
%else
%global httpd_group apache
%endif

%define release_prefix dev%(date +%%Y%%m%%d)
Name:           kolab-utils
Version:        3.1
Release:        0.1.dev20140624.git8ebf74a1%{?dist}
Summary:        Kolab Utilities

Group:          System Environment/Base

License:        GPLv2+
URL:            http://www.kolab.org/about/kolab-utils

Source0:        %{name}-git-master.tar.gz

BuildRequires:  cmake
BuildRequires:  libcurl-devel
BuildRequires:  libkolab-devel
%if 0%{?rhel} > 6 || 0%{?fedora} > 16
BuildRequires:  kdepimlibs-devel >= 4.9
%else
# Note: available within kolabsys.com infrastructure only, as being (essentially) a
# fork of various kde 4.9 libraries that depend on kde*, and that have no place in el6.
BuildRequires:  libcalendaring-devel
%endif
BuildRequires:  qt-devel

%description
Utilities for Kolab

%prep
%setup -q -n %{name}-master

%build
mkdir -p build
pushd build

%if 0%{?suse_version}
cmake \
%else
%cmake \
%endif
    -Wno-fatal-errors -Wno-errors \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DINCLUDE_INSTALL_DIR=%{_includedir} \
    -DLIB_INSTALL_DIR=%{_libdir} \
    -DBIN_INSTALL_DIR=%{_bindir} \
%if 0%{?rhel} < 7 && 0%{?fedora} < 17
    -DUSE_LIBCALENDARING=ON \
%endif
    ..
make
popd

%install
pushd build
make install DESTDIR=%{buildroot}
popd

mkdir -p %{buildroot}/%{_sharedstatedir}/kolab-freebusy/

%files
%if 0%{?suse_version}
%exclude %{_prefix}/com
%endif
%{_bindir}/*
%{_libdir}/libkolabutils.so
%attr(0750,root,%{httpd_group}) %dir %{_sharedstatedir}/kolab-freebusy

%changelog
* Tue Oct 29 2013 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.5-3
- Do not require httpd at all
- Set QT_NO_GLIB=1 in cron

* Wed May 22 2013 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.5-2
- Rebuild against latest libkolabxml, libkolab

* Mon Mar 11 2013 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.5-1
- New upstream release

* Tue Feb 19 2013 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.4-2
- Obsolete shipping our own kolab-freebusy/index.php

* Tue Nov 20 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.4-1
- New upstream version

* Tue Nov  6 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.3-3
- Ship libkolabutils.so

* Mon Nov  5 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.3-2
- Fix build on Enterprise Linux 6
- New upstream release

* Sat Sep 22 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.2-2
- Fix cronjob to ensure a single freebusy generator/aggregator runs at
  any given interval

* Wed Aug 15 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.2-1
- New upstream version 3.0.2

* Tue Aug  7 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.1-1
- New upstream release

* Mon Aug  6 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.0-3
- Apply patch for #944
- Add standard cron.d job to generate/aggregate freebusy

* Fri Aug  3 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0.0-1
- First version for alpha

* Wed Aug  1 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0-0.4
- Latest snapshot, resolves #906

* Tue Jul 31 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0-0.3
- Latest snapshot

* Wed Jul 25 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 3.0-0.1
- This is a package too
