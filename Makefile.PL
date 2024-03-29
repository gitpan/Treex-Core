
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "interface to linguistic structures and processing units in Treex",
  "AUTHOR" => "Treex team <treex\@ufal.mff.cuni.cz>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "Test::Output" => 0,
    "Test::Requires" => 0,
    "constant" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Treex-Core",
  "EXE_FILES" => [
    "bin/ttred",
    "bin/treex"
  ],
  "LICENSE" => "perl",
  "NAME" => "Treex::Core",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Encode" => 0,
    "English" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::HomeDir" => "0.97",
    "File::Path" => "2.08",
    "File::ShareDir" => 0,
    "File::Slurp" => "9999.19",
    "File::Spec" => 0,
    "File::Temp" => 0,
    "File::Which" => 0,
    "File::chdir" => 0,
    "IO::Handle" => 0,
    "IO::Interactive" => 0,
    "LWP::Simple" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Locale::Language" => 0,
    "Module::Reload" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::SemiAffordanceAccessor" => "0.09",
    "MooseX::SemiAffordanceAccessor::Role::Attribute" => "0.09",
    "PerlIO::via::gzip" => 0,
    "Readonly" => 0,
    "Scalar::Util" => 0,
    "Storable" => 0,
    "Text::Balanced" => 0,
    "Time::HiRes" => 0,
    "Treex::PML" => 0,
    "Treex::PML::Factory" => 0,
    "Treex::PML::IO" => 0,
    "Treex::PML::Node" => 0,
    "Treex::PML::Struct" => 0,
    "UNIVERSAL::DOES" => 0,
    "YAML" => "0.72",
    "autodie" => 0,
    "base" => 0,
    "integer" => 0,
    "namespace::autoclean" => 0,
    "open" => 0,
    "strict" => 0,
    "utf8" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.08664",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


