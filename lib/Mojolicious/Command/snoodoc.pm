package Mojolicious::Command::snoodoc;

use Mojo::Base 'Mojolicious::Command';

use Mojo::UserAgent;
use Mojo::URL;

our $VERSION = '0.01';

has description => 'Quick reference tool for the reddit API';



sub run {
    my ($self, $endpoint) = @_;

    my $ua = Mojo::UserAgent->new();
    my $url = 'http://www.reddit.com/dev/api';

    my $container = $ua->get($url)->res->dom->at("div#$endpoint");

    my $scopes = $container->find('.api-badge\ oauth-scope')->map('text')->map(sub { "* $_" } )->join("\n");

    say "Documentation for $endpoint";

    say "\n[OAuth Scopes]";
    say "$scopes\n";

    my $desc = $container->find('.md p')->map('text')->join("\n\n");


    say "Description\n $desc\n";

    # get description
    #
    # get params

}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Command::snoodoc - Blah blah blah

=head1 SYNOPSIS

  use Mojolicious::Command::snoodoc;

=head1 DESCRIPTION

Mojolicious::Command::snoodoc is

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Curtis Brandt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
