Name:		Sprog
Version:	0.14
Release:	1
Epoch:		0
Summary:	A graphical tool which anyone can use to build programs by plugging parts together.
Group:		Applications/System
License:	Artistic
URL:		http://sprog.sourceforge.net/
Packager:	Grant McLean (grantm@cpan.org)
Vendor:		Grant McLean (grantm@cpan.org)
Source:		http://osdn.dl.sourceforge.net/sprog/%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/root-%{name}-%{version}
Prefix:		%{_prefix}
AutoReq:	no
BuildArch:	noarch
BuildRequires:	perl >= 0:5.6
Requires:	perl >= 0:5.6, perl-Gtk2, perl-Gtk2-GladeXML, perl-Gnome2-Canvas, perl-YAML, perl-Pod-Simple

%description
Sprog is a tool for working with data. It allows you to do all the things those
clever Unix geeks can do with their cryptic command lines but you can now do it
all with point-n-click and drag-n-drop.

A Sprog machine has many similarities to a shell script. It is built from small
reusable parts (called gears) that are connected together to filter and massage
your data. Once you have built a machine, you can save it and run it again and
again to automatically perform repetitive tasks.

%prep
%setup -n %{name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%makeinstall
%{__rm} -rf %{buildroot}%{perl_archlib}/perllocal.pod %{buildroot}%{perl_vendorarch}/auto/Alias/.packlist

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,0755)
%{_bindir}/*
%{_datadir}/*
%{_libdir}/*

%changelog
*Thu Jun 23 2005 Grant McLean <grant@mclean.net.nz> - 0.11-1
- Leave .pm files to go to default location - wrapper script will cope

*Tue Jun 14 2005 Gavin Brown <gavin.brown@uk.com> - 0.10-2
- Hard-coded where .pm files go for when building on Debian

*Tue Jun 14 2005 Grant McLean <grant@mclean.net.nz> - 0.10-1
- New upstream version
- Removed perl-Class-Accessor dependency
- Bumped up Perl version dependency
- Tweaked Gavin's configs for vendor/packager

*Wed Jun 01 2005 Gavin Brown <gavin.brown@uk.com> - 0.09-1
- Initial package.
