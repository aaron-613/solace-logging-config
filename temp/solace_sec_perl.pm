package SecSolaceRoutines;


# Looks through all elements of the disconnect_logs hash, and returns the highest (SOLAC or SOLDV) event tag it finds
sub find_highest_event_tag {
    my $default_tag = "SOLDVTLDNSOLDVWARN:";  # default if it can't find an appropriate tag
    my $all_tags = "";
    for (keys %disconnect_logs) {
        $all_tags .= $disconnect_logs{$_}->{'tag'};
    }
    if    ($all_tags =~ /(SOLAC....SOLACCRIT:)/) { return $1; }
    elsif ($all_tags =~ /(SOLAC....SOLACWARN:)/) { return $1; }
    elsif ($all_tags =~ /(SOLDV....SOLDVCRIT:)/) { return $1; }
    elsif ($all_tags =~ /(SOLDV....SOLDVCRIT:)/) { return $1; }
    else { return $default_tag; }
}

# Returns a timestamp how Nimbus likes it: 'Oct 28 16:04:54'
sub get_nimbus_friendly_timestamp {
    my $time = `date +"%b %e %X"`;
    chomp $time;
    return $time;
}


# Returns the hostname of this logging server
sub get_hostname {
    my $host = `hostname`;
    chomp $host;
    return $host;
}


# Creates a new disconnect log entry in the hash
sub  build_mass_disconnect_log {
    my $preface = shift;
    my $event_tag = &find_highest_event_tag();
    my $timestamp = &get_nimbus_friendly_timestamp();
    my $hostname = &get_hostname();
    my $mass_log = "";
    for (keys %disconnect_logs) {
        if ($disconnect_logs{$_}->{'status'} !~ /OLD/) {
            $mass_log .= "$disconnect_logs{$_}->{'status'} - Bridge '$disconnect_logs{$_}->{'bridgename'} in VPN '$disconnect_logs{$_}->{'vpn'}` on '$disconnect_logs{$_}->{'appliance'}`;  ";
        }
    }
    my $num_disconnects = &cleanup_disconnect_logs();
    if ($num_disconnects == 0) { return; }
    return "$timestamp $hostname $event_tag $preface ($num_disconnects disconnects detected) : $mass_log";
}


# Adds a bridge disconnection log
sub add_disconnect_log {
    my $tag = shift;
    my $cluster = shift;
    my $appliance = shift;
    my $vpn = shift;
    my $bridgename = shift;
    my $key = "${cluster}__${vpn}__${bridgename}";
    $disconnect_logs{$key}->{'status'} = "DISCONNECT";
    $disconnect_logs{$key}->{'tag'} = $tag;
    $disconnect_logs{$key}->{'cluster'} = $cluster;
    $disconnect_logs{$key}->{'appliance'} = $appliance;
    $disconnect_logs{$key}->{'vpn'} = $vpn;
    $disconnect_logs{$key}->{'bridgename'} = $bridgename;
    return 1;
}


# Modifies an existing disconnect log to say that it has either reconnected (same appliance) or failed-over (same cluster)
sub delete_disconnect_log {
    my $cluster = shift;
    my $vpn = shift;
    my $bridgename = shift;
    my $key = "${cluster}__${vpn}__${bridgename}";
    delete $disconnect_logs{$key};
    return 1;
}

sub update_disconnect_log {
    my $cluster = shift;
    my $appliance = shift;
    my $vpn = shift;
    my $bridgename = shift;
    my $key = "${cluster}__${vpn}__${bridgename}";
    # Only update if it exists (we shouldn't actually be able to call this if it doesn't)
    if (exists $disconnect_logs{$key}) {
        if ($disconnect_logs{$key}->{'appliance'} ne $appliance) {
            $disconnect_logs{$key}->{'status'} = "FAILOVER";
        } else {
            $disconnect_logs{$key}->{'status'} = "RECONNECT";
        }
    } else {
        return 0;
    }
    return 1;
}


# This subroutine will "obsolete" old disconnect logs, and remove reconnected and failover logs
sub cleanup_disconnect_logs {
    my $num_disconnects = scalar keys %disconnect_logs;
    for (keys %disconnect_logs) {
        delete $disconnect_logs{$_};
    }
    return $num_disconnects;
}



#build_bridge_flap_log
sub build_bridge_flap_log {
    my $tag = shift;
    my $cluster = shift;
    my $appliance = shift;
    my $vpn = shift;
    my $bridgename = shift;
    my $timestamp = &get_nimbus_friendly_timestamp();
    return "$timestamp $appliance $tag ** SOLACE BRIDGE FLAPPING ** Bridge $bridgename in VPN $vpn on $appliance";
}

my($hello) = "hello!"

# SUCCESS!
1;

