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
            info => [ [], [] ],
        },
        api => {
            spec => [ [], [] ],
        },
        avail => {
            datacenters => [ [], [] ],
            distributions => [ [], [ 'distributionid' ] ],
            kernels => [ [], [ 'isxen', 'kernelid' ] ],
            linodeplans => [ [ 'planid' ], [] ],
            stackscripts => [ [], [qw( keywords distributionid distributionvendor )] ],
        },
        domain => {
            create => [ [ 'domain', 'type' ], [qw( status ttl_sec expire_sec master_ips refresh_sec soa_email retry_sec axfr_ips description )] ],
            delete => [ [ 'domainid' ], [] ],
            list => [ [], [ 'domainid' ] ],
            update => [ [ 'domainid' ], [qw( status domain ttl_sec expire_sec type master_ips refresh_sec soa_email axfr_ips retry_sec description )] ],
        },
        domain_resource => {
            create => [ [qw( domainid type )], [qw( target ttl_sec port weight priority protocol name )] ],
            delete => [ [ 'resourceid', 'domainid' ], [] ],
            list => [ [ 'domainid' ], [ 'resourceid' ] ],
            update => [ [ 'resourceid' ], [qw( target domainid ttl_sec port weight priority protocol name )] ],
        },
        linode => {
            boot => [ [ 'linodeid' ], [ 'configid' ] ],
            clone => [ [qw( planid paymentterm linodeid datacenterid )], [] ],
            create => [ [qw( planid paymentterm datacenterid )], [] ],
            delete => [ [ 'linodeid' ], [ 'skipchecks' ] ],
            list => [ [], [ 'linodeid' ] ],
            reboot => [ [ 'linodeid' ], [ 'configid' ] ],
            resize => [ [ 'planid', 'linodeid' ], [] ],
            shutdown => [ [ 'linodeid' ], [] ],
            update => [ [ 'linodeid' ], [qw( alert_bwquota_threshold alert_bwin_threshold alert_cpu_threshold alert_cpu_enabled alert_diskio_enabled label backupweeklyday alert_bwquota_enabled watchdog lpm_displaygroup alert_bwin_enabled alert_bwout_enabled alert_bwout_threshold alert_diskio_threshold backupwindow )] ],
        },
        linode_config => {
            create => [ [qw( linodeid label kernelid )], [qw( comments helper_xen devtmpfs_automount rootdevicecustom rootdevicero helper_depmod helper_disableupdatedb rootdevicenum disklist runlevel ramlimit )] ],
            delete => [ [ 'configid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( comments helper_xen devtmpfs_automount rootdevicecustom linodeid rootdevicero label helper_depmod helper_disableupdatedb rootdevicenum disklist runlevel kernelid ramlimit )] ],
        },
        linode_disk => {
            create => [ [qw( type size linodeid label )], [] ],
            createfromdistribution => [ [qw( size rootpass linodeid distributionid label )], [ 'rootsshkey' ] ],
            createfromstackscript => [ [qw( size linodeid rootpass distributionid stackscriptudfresponses stackscriptid label )], [] ],
            delete => [ [ 'diskid', 'linodeid' ], [] ],
            duplicate => [ [ 'diskid', 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'diskid' ] ],
            resize => [ [qw( diskid linodeid size )], [] ],
            update => [ [ 'diskid' ], [qw( linodeid isreadonly label )] ],
        },
        linode_ip => {
            addprivate => [ [ 'linodeid' ], [] ],
            list => [ [ 'linodeid' ], [ 'ipaddressid' ] ],
        },
        linode_job => {
            list => [ [ 'linodeid' ], [ 'pendingonly', 'jobid' ] ],
        },
        nodebalancer => {
            create => [ [ 'paymentterm', 'datacenterid' ], [ 'label', 'clientconnthrottle' ] ],
            delete => [ [ 'nodebalancerid' ], [] ],
            list => [ [], [ 'nodebalancerid' ] ],
            update => [ [ 'nodebalancerid' ], [ 'label', 'clientconnthrottle' ] ],
        },
        nodebalancer_config => {
            create => [ [ 'nodebalancerid' ], [qw( check_path check_body stickiness port check check_timeout check_attempts check_interval protocol algorithm )] ],
            delete => [ [ 'configid' ], [] ],
            list => [ [ 'nodebalancerid' ], [ 'configid' ] ],
            update => [ [ 'configid' ], [qw( check_path check_body stickiness port check_timeout check check_attempts check_interval protocol algorithm )] ],
        },
        nodebalancer_node => {
            create => [ [qw( configid address label )], [ 'mode', 'weight' ] ],
            delete => [ [ 'nodeid' ], [] ],
            list => [ [ 'configid' ], [ 'nodeid' ] ],
            update => [ [ 'nodeid' ], [qw( address mode weight label )] ],
        },
        stackscript => {
            create => [ [qw( script distributionidlist label )], [qw( rev_note description ispublic )] ],
            delete => [ [ 'stackscriptid' ], [] ],
            list => [ [], [ 'stackscriptid' ] ],
            update => [ [ 'stackscriptid' ], [qw( script rev_note ispublic label distributionidlist description )] ],
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

    return $old_validation, $new_validation;
}
