use strict;
use warnings;
package RT::Extension::Filesender;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-Filesender - [One line description of module's purpose here]

=head1 DESCRIPTION

Filesender integration to Request Tracker

=head1 RT VERSION

Works with RT > 4.2.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::Filesender');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Andrius Kulbis <lt>andrius.kulbis@gmail.com<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Andrius Kulbis

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
