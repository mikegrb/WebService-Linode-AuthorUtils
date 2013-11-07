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
            estimateinvoice => [ ['mode'], [qw( paymentterm linodeid planid )] ],
            info            => [ [],       [] ],
            paybalance      => [ [],       [] ],
            updatecard => [ [qw( ccexpmonth ccexpyear ccnumber )], [] ],
        },
        api => { spec => [ [], [] ], },
        avail => {
            datacenters   => [ [], [] ],
            distributions => [ [], ['distributionid'] ],
            kernels       => [ [], [ 'kernelid', 'isxen' ] ],
            linodeplans   => [ [], ['planid'] ],
            stackscripts =>
                [ [], [qw( distributionid keywords distributionvendor )] ],
        },
        domain => {
            create => [
                [ 'type', 'domain' ],
                [   qw( refresh_sec retry_sec master_ips expire_sec soa_email axfr_ips description ttl_sec status )
                ]
            ],
            delete => [ ['domainid'], [] ],
            list   => [ [],           ['domainid'] ],
            update => [
                ['domainid'],
                [   qw( refresh_sec retry_sec master_ips type expire_sec domain soa_email axfr_ips description ttl_sec status )
                ]
            ],
        },
        domain_resource => {
            create => [
                [qw( type domainid )],
                [qw( protocol name weight target priority ttl_sec port )]
            ],
            delete => [ [ 'resourceid', 'domainid' ], [] ],
            list => [ ['domainid'], ['resourceid'] ],
            update => [
                ['resourceid'],
                [qw( weight target priority ttl_sec domainid port protocol name )]
            ],
        },
        linode => {
            boot => [ ['linodeid'], ['configid'] ],
            clone => [ [qw( linodeid paymentterm datacenterid planid )], [] ],
            create => [ [qw( datacenterid planid paymentterm )], [] ],
            delete => [ ['linodeid'], ['skipchecks'] ],
            list   => [ [],           ['linodeid'] ],
            mutate => [ ['linodeid'], [] ],
            reboot => [ ['linodeid'], ['configid'] ],
            resize => [ [ 'linodeid', 'planid' ], [] ],
            shutdown => [ ['linodeid'], [] ],
            update => [
                ['linodeid'],
                [   qw( alert_diskio_threshold lpm_displaygroup watchdog alert_bwout_threshold ms_ssh_disabled ms_ssh_ip ms_ssh_user alert_bwout_enabled alert_diskio_enabled ms_ssh_port alert_bwquota_enabled alert_bwin_threshold backupweeklyday alert_cpu_enabled alert_bwquota_threshold backupwindow alert_cpu_threshold alert_bwin_enabled label )
                ]
            ],
            webconsoletoken => [ ['linodeid'], [] ],
        },
        linode_config => {
            create => [
                [qw( kernelid linodeid label )],
                [   qw( rootdevicero helper_disableupdatedb rootdevicenum comments rootdevicecustom devtmpfs_automount ramlimit runlevel helper_depmod helper_xen disklist )
                ]
            ],
            delete => [ [ 'linodeid', 'configid' ], [] ],
            list => [ ['linodeid'], ['configid'] ],
            update => [
                ['configid'],
                [   qw( helper_disableupdatedb rootdevicero comments rootdevicenum rootdevicecustom kernelid runlevel ramlimit devtmpfs_automount helper_depmod linodeid helper_xen disklist label )
                ]
            ],
        },
        linode_disk => {
            create => [ [qw( label size type linodeid )], [] ],
            createfromdistribution => [
                [qw( rootpass linodeid distributionid size label )],
                ['rootsshkey']
            ],
            createfromstackscript => [
                [   qw( size label linodeid stackscriptid distributionid rootpass stackscriptudfresponses )
                ],
                []
            ],
            delete    => [ [ 'linodeid', 'diskid' ],   [] ],
            duplicate => [ [ 'diskid',   'linodeid' ], [] ],
            list => [ ['linodeid'], ['diskid'] ],
            resize => [ [qw( diskid linodeid size )], [] ],
            update => [ ['diskid'], [qw( linodeid label isreadonly )] ],
        },
        linode_ip => {
            addprivate => [ ['linodeid'], [] ],
            list       => [ ['linodeid'], ['ipaddressid'] ],
        },
        linode_job => { list => [ ['linodeid'], [ 'pendingonly', 'jobid' ] ], },
        nodebalancer => {
            create => [
                [ 'paymentterm',        'datacenterid' ],
                [ 'clientconnthrottle', 'label' ]
            ],
            delete => [ ['nodebalancerid'], [] ],
            list   => [ [],                 ['nodebalancerid'] ],
            update => [ ['nodebalancerid'], [ 'label', 'clientconnthrottle' ] ],
        },
        nodebalancer_config => {
            create => [
                ['nodebalancerid'],
                [   qw( protocol check check_path check_interval algorithm check_attempts stickiness check_timeout check_body port )
                ]
            ],
            delete => [ ['configid'],       [] ],
            list   => [ ['nodebalancerid'], ['configid'] ],
            update => [
                ['configid'],
                [   qw( check_body stickiness check_attempts check_timeout algorithm port check protocol check_path check_interval )
                ]
            ],
        },
        nodebalancer_node => {
            create => [ [qw( label address configid )], [ 'mode', 'weight' ] ],
            delete => [ ['nodeid'],                     [] ],
            list   => [ ['configid'],                   ['nodeid'] ],
            update => [ ['nodeid'], [qw( mode label address weight )] ],
        },
        stackscript => {
            create => [
                [qw( label distributionidlist script )],
                [qw( rev_note description ispublic )]
            ],
            delete => [ ['stackscriptid'], [] ],
            list   => [ [],                ['stackscriptid'] ],
            update => [
                ['stackscriptid'],
                [   qw( distributionidlist description script ispublic rev_note label )
                ]
            ],
        },
        test => { echo => [ [], [] ], },
        user => { getapikey => [ [ 'username', 'password' ], [] ], },


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


    return $old_validation, $new_validation;
}
