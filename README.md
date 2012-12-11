# NAME

Plack::Middleware::StatsD - Plack middleware for logging request/response data with StatsD

# VERSION

version 0.0100

# SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::StatsD;

    my $app = sub { ... } # as usual

    # StatsD Options
    my %options = (
        host => '127.0.0.1',
        port => 8125,
        sample_rate => 0.5,
        prefix => 'myapp',
    );

    builder {
        enable "Plack::Middleware::StatsD", %options;
        $app;
    };

With the above in place, [Plack::Middleware::StatsD](http://search.cpan.org/perldoc?Plack::Middleware::StatsD) will increment counters to
`PREFIX.STATUS_CODE` and `PREFIX./url/path.STATUS_CODE` to your statsd server.

It will also time your responses under `PREFIX./url/path.time` to your statsd
server as well.

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.