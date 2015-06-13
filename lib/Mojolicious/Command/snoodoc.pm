package Mojolicious::Command::snoodoc;

use Mojo::Base 'Mojolicious::Command';

use Mojo::UserAgent;
use Mojo::URL;

our $VERSION = '0.01';

has description => 'Quick reference tool for the reddit API';

sub _pretty_print {
    my ($self, $scopes, $desc, $params) = @_;

    say "OAuth Scopes:\n\n$scopes\n";

    say "Description:\n\n$desc\n";

    say "Parameters:\n\n$params";
}

sub _get_info {
    my ($self, $container) = @_;

    my $scopes = $container->find('.api-badge\ oauth-scope')->map(    #
        sub { ' * ' . $_->text } # indentaion
    )->join("\n\n");

    my $desc = $container->find('.md p')->map(
        sub {
            ## keep a bit of identation for output
            return ' ' . $_->text unless $_->text =~ /\bSee also\b/;

            # use strip() instead?
            return 'See also: ', $_->find('a')->map(
                sub {
                    my $attr = $_->attr('href');

                    # remove leading #POST/GET
                    $attr =~ s/^#[A-Z]{3,4}_//;

                    # look like URL
                    $attr =~ s@_@/@g;
                    $attr =~ s/%7B/{/g;
                    $attr =~ s/%7D/}/g;
                    " $attr";    # indentation
                }
            )->join("\n\n");
        }
    )->join("\n\n");

    my $params = $container->find('table.parameters tr')->map(
        sub {
            my $param = $_->at('th')->text;

            # some parameters don't have a description
            if (my $param_desc = $_->at('td p')) {
                $param .= ': ' . $param_desc->text;
            }

            # indentation
            " $param";
        }
    )->join("\n\n");

    $self->_pretty_print($scopes, $desc, $params);
}

sub run {
    my ($self, $endpoint) = @_;

    $endpoint =~ s@^/@@;     # remove leading /
    $endpoint =~ s@/@_@g;    # look like URL fragment

    my $ua = Mojo::UserAgent->new();
    my $url = 'http://www.reddit.com/dev/api';

    my $container = $ua->get($url)->res->dom->at('div[id$=' . $endpoint . ']');

    $self->_get_info($container);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Command::snoodoc - Quick reference tool for the Reddit API

=head1 SYNOPSIS

  $ mojo snoodoc /api/save | less
  $ mojo snoodoc /api/v1/me/prefs | less

=head1 DESCRIPTION

Easily print out documentation of specific Reddit API endpoints. Output
shows a description of the given endpoint, along with any OAuth scopes
and parameters.

See the reddit L<documentation|http://www.reddit.com/dev/api> for details.

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Curtis Brandt

=head1 LICENSE

The (two-clause) FreeBSD License. See LICENSE for details.

=head1 SEE ALSO

L<Mojo::Snoo>

L<reddit documentation|http://www.reddit.com/dev/api>

=cut
