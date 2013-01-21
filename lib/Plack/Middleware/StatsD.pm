use strict;
use warnings;
package Plack::Middleware::StatsD;
use parent qw(Plack::Middleware);
use Etsy::StatsD;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw(
    host port sample_rate prefix stat_name_mapper whitelist
    _sd
);
use Time::HiRes qw( time );

# ABSTRACT: Plack middleware for logging request/response data with StatsD

sub prepare_app {
    my ($self) = @_;

    die "No Host" unless $self->host;
    die "No Port" unless $self->port;

    $self->prefix( '' ) unless defined $self->prefix;
    $self->sample_rate( 1 ) unless defined $self->sample_rate;

    $self->whitelist( sub{ 1 } ) unless ref $self->whitelist eq "CODE";
    $self->stat_name_mapper( sub{ shift->path } )
        unless ref $self->stat_name_mapper eq "CODE";

    my $sd = Etsy::StatsD->new( $self->host, $self->port, $self->sample_rate );
    $self->_sd( $sd )
}

sub call {
    my($self, $env) = @_;

    # Build Plack::Request
    my $req = Plack::Request->new( $env );

    my $start = time;
    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my ($res) = @_;

        return $res unless $self->whitelist->( $req );

        my ($end, $code) = ( time, $res->[0]);
        my $path = $self->stat_name_mapper->( $req );

        # Log the response time ( in ms )
        my $time = ( $end - $start ) * 1000;
        $self->_sd->timing( $self->_stat( "$path.time" ), $time );

        # Increment code counter
        $self->_sd->increment( $self->_stat( $code ) );
        # Increment code + path hcounter
        $self->_sd->increment( $self->_stat( "$path.$code" ) );

        return $res;
    });
}

sub _stat { shift->prefix . '.' . shift }

1;

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::StatsD;

    my $app = sub { ... } # as usual

    # StatsD Options
    my %options = (
        host => '127.0.0.1',
        port => 8125,
        sample_rate => 0.5,
        prefix => 'myapp',
        whitelist => sub {
            my ($req) = @_;
            ...
            # Return true to process, false to ignore
        },
        stat_name_mapper => sub {
            my ($req) = @_;
            ...
            # Return what to name the stat for this request
            return $req->path;
        },
    );

    builder {
        enable "Plack::Middleware::StatsD", %options;
        $app;
    };

With the above in place, L<Plack::Middleware::StatsD> will increment counters to
C<PREFIX.STATUS_CODE> and C<PREFIX./url/path.STATUS_CODE> to your statsd server.

It will also time your responses under C<PREFIX./url/path.time> to your statsd
server as well.


