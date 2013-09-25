#!/usr/bin/perl

use strict;
use warnings;

my %validation = (
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
);

foreach my $group (qw{avail domain domain_resource linode linode_config linode_disk linode_ip linode_job stackscript nodeblancer nodebalancer_config  nodebalancer_node  user}) {
    # print "=head2 $group\n\n";
    foreach my $method (keys %{$validation{$group}}) {
        print "=head3 ${group}_${method}\n\n";
        if (@{$validation{$group}{$method}[0]}) {
            print "Required Parameters:\n\n";
            print "=over 4\n\n";
            print "=item * $_\n\n" for @{$validation{$group}{$method}[0]};
            print "=back\n\n";
        }
        if (@{$validation{$group}{$method}[1]}) {
            print "Optional Parameters:\n\n";
            print "=over 4\n\n";
            print "=item * $_\n\n" for @{$validation{$group}{$method}[1]};
            print "=back\n\n";
        }
    }
}