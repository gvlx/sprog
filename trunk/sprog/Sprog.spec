Name:		Sprog
Version:	0.09
Release:	1
Epoch:		0
Summary:	A graphical tool which anyone can use to build programs by plugging parts together.
Group:		Applications/System
License:	Artistic
URL:		http://sprog.sourceforge.net/
Packager:	Gavin Brown (http://jodrell.net/)
Vendor:		Gavin Brown (http://jodrell.net/)
Source:		http://osdn.dl.sourceforge.net/sprog/%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/root-%{name}-%{version}
Prefix:		%{_prefix}
AutoReq:	no
BuildArch:	noarch
BuildRequires:	perl >= 0:5.00503
Requires:	perl >= 0:5.00503, perl-Gtk2, perl-Gtk2-GladeXML, perl-Gnome2-Canvas, perl-Class-Accessor, perl-YAML, perl-Pod-Simple

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
*Wed Jun 1 2005 Gavin Brown <gavin.brown@uk.com> - 0.09-1
- Initial package.
