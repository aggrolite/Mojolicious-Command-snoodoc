package Mojolicious::Command::snoodoc;

use Mojo::Base 'Mojolicious::Command';

use Mojo::UserAgent;
use Mojo::URL;

use Getopt::Long qw(GetOptionsFromArray);

our $VERSION = '0.03';

has description => 'Quick reference tool for the reddit API';

has usage => <<EOF;
Usage:

    mojo snoodoc <endpoint>
    mojo snoodoc --all

Options:

    --all, -a   Print a list of endpoints available

Example:

    mojo snoodoc /api/hide

EOF

has ua => sub { Mojo::UserAgent->new() };

has url => 'http://www.reddit.com/dev/api';

sub _print_all_endpoints {
    my $self = shift;

    $self->ua->get($self->url)->res->dom->at('div.toc')->find('a.section')->each(
        sub {

            # print section title
            say $_->text;

            $_->following->first->find('li a')->each(
                sub {

                    # convert paceholder tags, e.g. /by_id/{names}
                    $_->find('em')->each(sub { $_->replace('{' . $_->text . '}') });

                    # indent results
                    say ' ' . $_->text;
                }
            );
        }
    );
}

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
            unless ($_->text =~ /\bSee also\b/) {
                $_->find('*')->map('strip');    # get all text available
                return ' ' . $_->text;
            }

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
    my ($self, @args) = @_;

    GetOptionsFromArray(
        \@args,    #
        'all|a' => \my $all,
    );

    if ($all) {
        $self->_print_all_endpoints();
        return;
    }

    # assuming only one endpoint was given
    my $endpoint = shift @args;

    # do not continue without endpoint
    unless ($endpoint) {
        print $self->usage;
        return;
    }

    $endpoint =~ s@^/@@;     # remove leading /
    $endpoint =~ s@/@_@g;    # look like URL fragment

    my $container = $self->ua->get($self->url)->res->dom->at('div[id$=' . $endpoint . ']');

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
  $ mojo snoodoc --all

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
