#!/usr/bin/env perl

use strict;
use warnings;
use 5.018;

use Term::ANSIColor;
use List::Compare;

my ( $old, $new ) = get_old_new();

for my $group ( sort keys $old ) {
    unless ( exists $new->{$group} ) {
        say "Group $group no longer exists.\n";
        next;
    }

    for my $method ( sort keys $old->{$group} ) {
        unless ( exists $new->{$group}{$method} ) {
            say "Group $group.$method no longer exists.\n";
            next;
        }

        my $old_args = $old->{$group}{$method};
        my $new_args = $new->{$group}{$method};

        my $args = {
            'required' => List::Compare->new( $old_args->[0], $new_args->[0] ),
            'optional' => List::Compare->new( $old_args->[1], $new_args->[1] )
        };

        for my $type ( keys $args ) {
            next if $args->{$type}->is_LequivalentR();
            say "$group.$method difference in $type arguments: ";
            my @old = $args->{$type}->get_unique();
            print "\t";
            for my $differing ( $args->{$type}->get_symmetric_difference() ) {
                my $removed = grep { $_ eq $differing } @old;
                print colored( ( $removed ? '- ' : '+ ' ) . $differing . '  ',
                    ( $removed ? 'red' : 'green' ) );
            }
            say "\n";
        }

    }

    for my $method ( sort keys $new->{$group} ) {
        next if exists $old->{$group}{$method};
        say "New method $group.$method\n";
    }

}

for my $group ( sort keys $new ) {
    next if exists $old->{$group};
    say "New group $group\n";
}


sub get_old_new {
    my $old_validation = {
        account => {
            estimateinvoice => [ [ 'mode' ], [qw( linodeid paymentterm planid )] ],
            info => [ [], [] ],
            paybalance => [ [], [] ],
            updatecard => [ [qw( ccexpmonth ccexpyear ccnumber )], [] ],
        },
        api => {
            spec => [ [], [] ],
        },
        avail => {
            datacenters => [ [], [] ],
            distributions => [ [], [ 'distributionid' ] ],
            kernels => [ [], [ 'isxen', 'kernelid' ] ],
            linodeplans => [ [], [ 'planid' ] ],
            stackscripts => [ [], [qw( distributionid distributionvendor keywords )] ],
        },
        domain => {
            create => [ [ 'domain', 'type' ], [qw( axfr_ips description expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec )] ],
            delete => [ [ 'domainid' ], [] ],
            list => [ [], [ 'domainid' ] ],
            update => [ [ 'domainid' ], [qw( axfr_ips description domain expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec type )] ],
        },
        domain_resource => {
            create => [ [qw( domainid type )], [qw( name port priority protocol target ttl_sec weight )] ],
            delete => [ [ 'domainid', 'resourceid' ], [] ],
            list => [ [ 'domainid' ], [ 'resourceid' ] ],
            update => [ [ 'resourceid' ], [qw( domainid name port priority protocol target ttl_sec weight )] ],
        },
        linode => {
            boot => [ [ 'linodeid' ], [ 'configid' ] ],
            clone => [ [qw( datacenterid linodeid paymentterm planid )], [] ],
            create => [ [qw( datacenterid paymentterm planid )], [] ],
            delete => [ [ 'linodeid' ], [ 'skipchecks' ] ],
            list => [ [], [ 'linodeid' ] ],
            mutate => [ [ 'linodeid' ], [] ],
            reboot => [ [ 'linodeid' ], [ 'configid' ] ],
            resize => [ [ 'linodeid', 'planid' ], [] ],
            shutdown => [ [ 'linodeid' ], [] ],
            update => [ [ 'linodeid' ], [qw( alert_bwin_enabled alert_bwin_threshold alert_bwout_enabled alert_bwout_threshold alert_bwquota_enabled alert_bwquota_threshold alert_cpu_enabled alert_cpu_threshold alert_diskio_enabled alert_diskio_threshold backupweeklyday backupwindow label lpm_displaygroup ms_ssh_disabled ms_ssh_ip ms_ssh_port ms_ssh_user watchdog )] ],
            webconsoletoken => [ [ 'linodeid' ], [] ],
        },
        linode_config => {
            create => [ [qw( kernelid label linodeid )], [qw( comments devtmpfs_automount disklist helper_depmod helper_disableupdatedb helper_xen ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel )] ],
            delete => [ [ 'configid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( comments devtmpfs_automount disklist helper_depmod helper_disableupdatedb helper_xen kernelid label linodeid ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel )] ],
        },
        linode_disk => {
            create => [ [qw( label linodeid size type )], [] ],
            createfromdistribution => [ [qw( distributionid label linodeid rootpass size )], [ 'rootsshkey' ] ],
            createfromstackscript => [ [qw( distributionid label linodeid rootpass size stackscriptid stackscriptudfresponses )], [] ],
            delete => [ [ 'diskid', 'linodeid' ], [] ],
            duplicate => [ [ 'diskid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'diskid' ] ],
            resize => [ [qw( diskid linodeid size )], [] ],
            update => [ [ 'diskid' ], [qw( isreadonly label linodeid )] ],
        },
        linode_ip => {
            addprivate => [ [ 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'ipaddressid' ] ],
        },
        linode_job => {
            list => [ [ 'linodeid' ], [ 'jobid', 'pendingonly' ] ],
        },
        nodebalancer => {
            create => [ [ 'datacenterid', 'paymentterm' ], [ 'clientconnthrottle', 'label' ] ],
            delete => [ [ 'nodebalancerid' ], [] ],
            list => [ [], [ 'nodebalancerid' ] ],
            update => [ [ 'nodebalancerid' ], [ 'clientconnthrottle', 'label' ] ],
        },
        nodebalancer_config => {
            create => [ [ 'nodebalancerid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
            delete => [ [ 'configid' ], [] ],
            list => [ [ 'nodebalancerid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
        },
        nodebalancer_node => {
            create => [ [qw( address configid label )], [ 'mode', 'weight' ] ],
            delete => [ [ 'nodeid' ], [] ],
            list => [ [ 'configid' ], [ 'nodeid' ] ],
            update => [ [ 'nodeid' ], [qw( address label mode weight )] ],
        },
        stackscript => {
            create => [ [qw( distributionidlist label script )], [qw( description ispublic rev_note )] ],
            delete => [ [ 'stackscriptid' ], [] ],
            list => [ [], [ 'stackscriptid' ] ],
            update => [ [ 'stackscriptid' ], [qw( description distributionidlist ispublic label rev_note script )] ],
        },
        test => {
            echo => [ [], [] ],
        },
        user => {
            getapikey => [ [ 'password', 'username' ], [] ],
        },
    };

    my $new_validation = {

        account => {
            estimateinvoice => [ [ 'mode' ], [qw( linodeid paymentterm planid )] ],
            info => [ [], [] ],
            paybalance => [ [], [] ],
            updatecard => [ [qw( ccexpmonth ccexpyear ccnumber )], [] ],
        },
        api => {
            spec => [ [], [] ],
        },
        avail => {
            datacenters => [ [], [] ],
            distributions => [ [], [ 'distributionid' ] ],
            kernels => [ [], [ 'isxen', 'kernelid' ] ],
            linodeplans => [ [], [ 'planid' ] ],
            stackscripts => [ [], [qw( distributionid distributionvendor keywords )] ],
        },
        domain => {
            create => [ [ 'domain', 'type' ], [qw( axfr_ips description expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec )] ],
            delete => [ [ 'domainid' ], [] ],
            list => [ [], [ 'domainid' ] ],
            update => [ [ 'domainid' ], [qw( axfr_ips description domain expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec type )] ],
        },
        domain_resource => {
            create => [ [ 'domainid', 'type' ], [qw( name port priority protocol target ttl_sec weight )] ],
            delete => [ [ 'domainid', 'resourceid' ], [] ],
            list => [ [ 'domainid' ], [ 'resourceid' ] ],
            update => [ [ 'resourceid' ], [qw( domainid name port priority protocol target ttl_sec weight )] ],
        },
        linode => {
            boot => [ [ 'linodeid' ], [ 'configid' ] ],
            clone => [ [qw( datacenterid linodeid planid )], [ 'paymentterm' ] ],
            create => [ [ 'datacenterid', 'planid' ], [ 'paymentterm' ] ],
            delete => [ [ 'linodeid' ], [ 'skipchecks' ] ],
            list => [ [], [ 'linodeid' ] ],
            mutate => [ [ 'linodeid' ], [] ],
            reboot => [ [ 'linodeid' ], [ 'configid' ] ],
            resize => [ [ 'linodeid', 'planid' ], [] ],
            shutdown => [ [ 'linodeid' ], [] ],
            update => [ [ 'linodeid' ], [qw( alert_bwin_enabled alert_bwin_threshold alert_bwout_enabled alert_bwout_threshold alert_bwquota_enabled alert_bwquota_threshold alert_cpu_enabled alert_cpu_threshold alert_diskio_enabled alert_diskio_threshold backupweeklyday backupwindow label lpm_displaygroup ms_ssh_disabled ms_ssh_ip ms_ssh_port ms_ssh_user watchdog )] ],
            webconsoletoken => [ [ 'linodeid' ], [] ],
        },
        linode_config => {
            create => [ [qw( kernelid label linodeid )], [qw( comments devtmpfs_automount disklist helper_depmod helper_disableupdatedb helper_xen ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel )] ],
            delete => [ [ 'configid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( comments devtmpfs_automount disklist helper_depmod helper_disableupdatedb helper_xen kernelid label linodeid ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel )] ],
        },
        linode_disk => {
            create => [ [qw( label linodeid size type )], [] ],
            createfromdistribution => [ [qw( distributionid label linodeid rootpass size )], [ 'rootsshkey' ] ],
            createfromstackscript => [ [qw( distributionid label linodeid rootpass size stackscriptid stackscriptudfresponses )], [] ],
            delete => [ [ 'diskid', 'linodeid' ], [] ],
            duplicate => [ [ 'diskid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'diskid' ] ],
            resize => [ [qw( diskid linodeid size )], [] ],
            update => [ [ 'diskid' ], [qw( isreadonly label linodeid )] ],
        },
        linode_ip => {
            addprivate => [ [ 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'ipaddressid' ] ],
        },
        linode_job => {
            list => [ [ 'linodeid' ], [ 'jobid', 'pendingonly' ] ],
        },
        nodebalancer => {
            create => [ [ 'datacenterid', 'paymentterm' ], [ 'clientconnthrottle', 'label' ] ],
            delete => [ [ 'nodebalancerid' ], [] ],
            list => [ [], [ 'nodebalancerid' ] ],
            update => [ [ 'nodebalancerid' ], [ 'clientconnthrottle', 'label' ] ],
        },
        nodebalancer_config => {
            create => [ [ 'nodebalancerid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
            delete => [ [ 'configid' ], [] ],
            list => [ [ 'nodebalancerid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
        },
        nodebalancer_node => {
            create => [ [qw( address configid label )], [ 'mode', 'weight' ] ],
            delete => [ [ 'nodeid' ], [] ],
            list => [ [ 'configid' ], [ 'nodeid' ] ],
            update => [ [ 'nodeid' ], [qw( address label mode weight )] ],
        },
        stackscript => {
            create => [ [qw( distributionidlist label script )], [qw( description ispublic rev_note )] ],
            delete => [ [ 'stackscriptid' ], [] ],
            list => [ [], [ 'stackscriptid' ] ],
            update => [ [ 'stackscriptid' ], [qw( description distributionidlist ispublic label rev_note script )] ],
        },
        test => {
            echo => [ [], [] ],
        },
        user => {
            getapikey => [ [ 'password', 'username' ], [] ],
        },

    };


    return $old_validation, $new_validation;
}
