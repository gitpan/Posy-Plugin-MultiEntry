package Posy::Plugin::MultiEntry;
use strict;

=head1 NAME

Posy::Plugin::MultiEntry - Posy plugin to enable multiple entries to display for special entry files.

=head1 VERSION

This describes version B<0.01> of Posy::Plugin::MultiEntry.

=cut

our $VERSION = '0.01';

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
such as sorting in a different order, and so on.

This plugin replaces the 'select_entries' and 'sort_entries' actions.  When
using this plugin in conjunction with others which override 'sort_entries'
(such as L<Posy::Plugin::Info>), this plugin should go later in the plugins
list than them, otherwise its sort will be overridden.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<multi_entry_on>

Turn on multi-entry selection if the path-type is an entry.
(default: false)

=item B<multi_entry_change_type>

If multi_entry_on is true and multi_entry_change_type is true,
change the path-type to be 'category' or 'top_category'.
(default: true)

=item B<multi_entry_place_first>

If true, (and multi_entry_on) this will place the original entry first in
the displayed list of entries.  This could be used to make that entry
contain introductory information, followed by all the other entries.
(default: false)

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
    $self->{config}->{multi_entry_change_type} = 1
	if (!defined $self->{config}->{multi_entry_change_type});
    $self->{config}->{multi_entry_place_first} = 0
	if (!defined $self->{config}->{multi_entry_place_first});
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
Sets $flow_state->{entries}.  Assumes it hasn't
already been set.

=cut
sub select_entries {
    my $self = shift;
    my $flow_state = shift;

    if (($self->{path}->{type} eq 'entry'
	or $self->{path}->{type} eq 'top_entry')
	and $self->{config}->{multi_entry_on})
    {
	# select as for category
	if ($self->{path}->{cat_id} eq '') 
	{
	    @{$flow_state->{entries}} = keys %{$self->{files}};
	    $self->{path}->{type} = 'top_category'
		if $self->{config}->{multi_entry_change_type};
	}
	else
	{
	    $flow_state->{entries} = [];
	    foreach my $key (keys %{$self->{files}})
	    {
		if (($self->{files}->{$key}->{cat_id} 
		     eq $self->{path}->{cat_id}) # the same directory
		    or ($self->{files}->{$key}->{cat_id} 
			=~ m#^$self->{path}->{cat_id}/#) # a subdir
		   )
		{
		    push @{$flow_state->{entries}}, $key;
		}
	    }
	    $self->{path}->{type} = 'category'
		if $self->{config}->{multi_entry_change_type};
	}
    }
    else
    {
	$self->SUPER::select_entries($flow_state);
    }
} # select_entries

=head2 sort_entries

$self->sort_entries($flow_state);

If the config variable multi_entry_place_first is true,
extract the original entry from the list, sort the other
entries with the parent 'sort_entries' method, and
place the original entry first in the list.

Otherwise just use the parent sort.

=cut
sub sort_entries {
    my $self = shift;
    my $flow_state = shift;

    # no point sorting if there's only one
    if (@{$flow_state->{entries}} > 1)
    {
	if ($self->{config}->{multi_entry_on}
	    and $self->{config}->{multi_entry_place_first}
	    and exists $self->{files}->{$self->{path}->{file_key}})
	{
	    # remove the original entry-id from the list
	    my @entries = @{$flow_state->{entries}};
	    $flow_state->{entries} = [];
	    while (@entries)
	    {
		my $id = shift @entries;
		if ($id ne $self->{path}->{file_key})
		{
		    push @{$flow_state->{entries}}, $id;
		}
	    }
	    # sort the list
	    $self->SUPER::sort_entries($flow_state);
	    # put the original entry at the front of the list
	    unshift @{$flow_state->{entries}}, $self->{path}->{file_key};
	}
	else
	{
	    $self->SUPER::sort_entries($flow_state);
	}
    }
    1;	
} # sort_entries

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
