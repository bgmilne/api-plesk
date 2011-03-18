package API::Plesk::Component;

use strict;
use warnings;

use Carp;

sub new {
    my ( $class, %attrs ) = @_;
    $class = ref $class || $class;

    confess "Required API::Plesk object!" unless $attrs{plesk};

    return bless \%attrs, $class;
}

sub plesk { $_[0]->{plesk} }

sub check_required_params {
    my ( $self, $hash, @fields ) = @_;
    
    for my $key ( @fields ) {
        if ( ref $key ) {
            confess "Required any of this fields: " . join( ", ", @$key) . "!"
                unless grep { $hash->{$_} } @$key;
        } else {
            confess "Required field $key!" unless exists $hash->{$key};
        }
    }
}

# sort params in right order
sub sort_params {
    my ( $self, $params, @fields ) = @_;

    my @sorted;
    for ( @fields ) {
        push @sorted, {$_ => $params->{$_}}
            if exists $params->{$_};
    }
    return \@sorted;
}

sub check_hosting {
    my ( $self, $params, $required ) = @_;

    unless ( $params->{hosting} ) {
        confess "Required hosting!" if $required;
        return;
    }

    my $hosting = $params->{hosting};
    my $type = delete $hosting->{type};
    my $ip = delete $hosting->{ip_address};
    
    confess "Required ip_address" unless $ip;
    
    if ( $type eq 'vrt_hst' ) {

        $self->check_required_params($hosting, qw(ftp_login ftp_passwd));

        my @properties;
        for my $key ( keys %$hosting ) {
            push @properties, { property => [
                {name => $key}, 
                {value => $hosting->{$key}} 
            ]};
            delete $hosting->{$key};
        }
        push @properties, { ip_address => $ip };
        $hosting->{$type} = @properties ? \@properties : '';

        return;
    }

    elsif ( $type eq 'std_fwd' or $type eq 'frm_fwd' ) {
        
        confess "Required dest_url field!" unless $hosting->{dest_url};
        
        $hosting->{$type} = {
            dest_url => delete $hosting->{dest_url},
            ip_address => $ip,
        };

        return;
    }
    elsif ( $type eq 'none' ) {
        $hosting->{$type} = '';
        return;
    }

    confess "Unknown hosting type!";
}

1;