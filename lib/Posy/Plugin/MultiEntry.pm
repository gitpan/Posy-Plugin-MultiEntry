package Posy::Plugin::MultiEntry;
use strict;

=head1 NAME

Posy::Plugin::MultiEntry - Posy plugin to enable multiple entries to display for special entry files.

=head1 VERSION

This describes version B<0.03> of Posy::Plugin::MultiEntry.

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::MultiEntry
	...);

=head1 DESCRIPTION

This plugin enables the user to configure special 'entry' files to behave
like special "category" pages; Posy will display not only that entry,
but all the entries which would normally be selected when that category
is displayed.  This can be set up using a per-file config file,
which would enable one to use different settings for just that page,
such as sorting in a different order, showing a special sub-set
of files, and so on.

This plugin replaces the 'select_entries' action.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the config directory.

=over

=item B<multi_entry_on>

Turn on multi-entry selection if the path-type is an entry.
(default: false)

=item B<multi_entry_exclude>

Filter out the entries in the current category which match this pattern.
Note that one can actually set this to exclude the entry that
the multi_entry selection is being done with!

=item B<multi_entry_include>

Only keep the entries in the current category which match this pattern.
An entry has to both match the include pattern and not match the exclude
pattern for it to be included.

=back

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{multi_entry_on} = 0
	if (!defined $self->{config}->{multi_entry_on});
    $self->{config}->{multi_entry_exclude} = ''
	if (!defined $self->{config}->{multi_entry_exclude});
    $self->{config}->{multi_entry_include} = '.*'
	if (!defined $self->{config}->{multi_entry_include});
} # init

=head1 Flow Action Methods

Methods implementing actions.  All such methods expect a
reference to a flow-state hash, and generally will update
either that hash or the object itself, or both in the course
of their running.

=head2 select_entries

$self->select_entries($flow_state);

Select entries by looking at the path information.
Assumes that no entries have been selected before.

If this is an entry, and multi_entry_on is true, then
selects all entries as if this were a category, and sets
the path type to be category.

Otherwise, calls the parent method.

=cut
sub select_entries {
    my $self = shift;
    my $flow_state = shift;

    if (($self->{path}->{type} eq 'entry'
	or $self->{path}->{type} eq 'top_entry')
	and $self->{config}->{multi_entry_on})
    {
	# we are doing multi-entry!
	$self->debug(2, "MultiEntry: " . $self->{path}->{file_key});
	# select entries as for category
	# skipping the excluded entries
	# including the included entries
	$flow_state->{entries} = [];
	foreach my $key (keys %{$self->{files}})
	{
	    if (!($self->{config}->{multi_entry_exclude}
		  and $key =~ m#$self->{config}->{multi_entry_exclude}#
		 )
		  and $key =~ m#$self->{config}->{multi_entry_include}#
	       )
	    {
		if (($self->{path}->{cat_id} eq '')
		    or (($self->{files}->{$key}->{cat_id} 
			 eq $self->{path}->{cat_id}) # the same directory
			or ($self->{files}->{$key}->{cat_id} 
			    =~ m#^$self->{path}->{cat_id}/#)) # a subdir
		   )
		{
		    push @{$flow_state->{entries}}, $key;
		}
	    }
	}

	# reset the path type to 'category' and reset the config
	if ($self->{path}->{cat_id} eq '') 
	{
	    $self->{path}->{type} = 'top_category';
	}
	else
	{
	    $self->{path}->{type} = 'category';
	}
	$self->set_config($flow_state);
    }
    else
    {
	$self->SUPER::select_entries($flow_state);
    }
} # select_entries

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::MultiEntry

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Posy
    Posy::Core

    Test::More

=head1 SEE ALSO

perl(1).
Posy

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::MultiEntry
__END__
