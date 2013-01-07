use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Redmine::KPI',
    AUTHOR              => q{Fedor A Borshev <fedor@shogo.ru>},
    VERSION_FROM        => 'lib/Redmine/KPI.pm',
    ABSTRACT_FROM       => 'lib/Redmine/KPI.pm',
    'LICENSE'		=> 'mit',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 		=> 0,
	'Time::HiRes'		=> 0,
	'Badger::Class'		=> 0,
	'Class::Singleton' 	=> 0,
	'Class::Date'		=> 0,
	'Rose::URI'		=> 0,
	'Exporter::Lite'	=> 0,
	'XML::LibXML'		=> 0,
	'File::Slurp'		=> 0,
	'LWP::UserAgent'	=> 0,
	'Crypt::SSLeay'		=> 0,
	'Digest::MD5'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Redmine-KPI-*' },
);
