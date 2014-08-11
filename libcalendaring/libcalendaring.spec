Name:           libcalendaring
Version:        4.9.0
%define release_prefix dev%(date +%%Y%%m%%d)
Release:        2%{?dist}
Summary:        Library for Calendaring

Group:          System Environment/Libraries
License:        LGPLv2+
URL:            http://www.kolab.org/about/libcalendaring

Source0:        %{name}-git-master.tar.gz

BuildRequires:  boost-devel
BuildRequires:  cmake
BuildRequires:  cyrus-sasl-devel
BuildRequires:  gcc-c++
BuildRequires:  libical-devel
%if 0%{?suse_version}
BuildRequires:  qt-devel
%else
BuildRequires:  qt4-devel
%endif

#Requires:	

%description
Advanced calendaring library for Kolab, based on parts of KDE >= 4.9

%package devel
Summary:        Development headers
Group:          System Environment/Libraries
Requires:       %{name} = %{version}-%{release}

%description devel
These are development headers. Don't bother.

%prep
%setup -q -n %{name}-master

%build
mkdir build
pushd build
%if 0%{?suse_version}
cmake \
%else
%cmake \
%endif
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_PREFIX=%{_prefix} \
    -DLIB_INSTALL_DIR=%{_libdir} \
    ..

popd build

%install
pushd build
make install DESTDIR=%{buildroot}
popd

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%{_libdir}/libcalendaring-*.so.*

%files devel
%{_includedir}/calendaring
%{_libdir}/libcalendaring*.so

%changelog
* Fri Aug  3 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 4.9.0-1
- New upstream version 4.9.0

* Wed Jul 25 2012 Jeroen van Meeuwen <vanmeeuwen@kolabsys.com> - 4.9-1
- This too is a package
