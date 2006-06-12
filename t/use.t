#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 21;
use Test::Exception;
use English '-no_match_vars';

require_ok( 'CGI::FormBuilder' );

use blib;

my $fmplib = 'CGI::FormBuilder::Mail::FormatMultiPart';
require_ok( $fmplib );

my $fmp = undef;

lives_ok 
    { $fmp = $fmplib->new(); }
    'new without any params';

ok( defined $fmp,           'constructor return undefined'          );
ok( ref $fmp,               'constructor return not a reference'    );
ok( $fmp->isa('HASH'),      'constructor return not a hash ref'     );
ok( $fmp->isa( 'CGI::FormBuilder::Mail::FormatMultiPart' ),
                            'costructor return not right class obj' );

my $form = undef;
my $form_name = q{cgi_fb_mail_fmp};
my $inputs = {
    test1   => 'test one',
    test2   => 'test two',
};

lives_ok
    {   $form = CGI::FormBuilder->new(
            name        => $form_name,
            method      => 'get',
        );
        $form->field( 
            name  => $_, 
            value => $inputs->{$_}, 
            force => 1,
        ) for sort keys %{$inputs};
    }
    'could not get CGI::FormBuilder obj for tests';

my $email = getpwuid($REAL_USER_ID).'@localhost';

my $test1 = $form->field('test1');
my $test2 = $form->field('test2');

diag("\n");
diag("testing form: test1 = '$test1', test2 = '$test2'\n");
diag("sending form e-mail to $email\n");

my $main_params = {
    form        => $form,
    subject     => 'CGI::FormBuilder::Mail::FormatMultiPart build test',
    to          => $email,
    from        => $email,
    smtp        => 'localhost',
    cc          => undef,
    bcc         => undef,

};

throws_ok
    {   $fmp = $fmplib->new( blah => 'blah', lame => { } );
        $fmp->mailresults();
    } 
    qr{No CGI::FormBuilder passed as form arg}i,
    'no throw against bad params checking FormBuilder as form param';

for (qw( subject to from smtp cc bcc )) {
    throws_ok
        {   my $params = { %{$main_params} };
            $params->{$_} = { };
            $fmp = $fmplib->new( %{$params} );
            $fmp->mailresults( );
        }
        qr{Address/subject args should all be scalars}i,
        'no throw against non-scalar mailer args';
}

for (qw( to from smtp )) {
    throws_ok 
        {   my $params = { %{$main_params} };
            $params->{$_} = undef;
            $fmp = $fmplib->new( %{$params} );
            $fmp->mailresults( %{$params} );
        }
        qr{Cannot send mail without to, from, and smtp args}i,
        'no throw against missing required mailer params';
}

throws_ok
    {   my $params = { %{$main_params} };
        $params->{smtp} = 'a bogus smtp server string';
        $fmp = $fmplib->new( %{$params} );
        $fmp->mailresults( %{$params} );
    }
    qr{arg 'smtp' in bad format}i,
    'no throw against bad smtp mailer param';


lives_ok
    {   my $params = { %{$main_params} };
        $params->{smtp} = '127.0.0.1',
        $fmp = $fmplib->new( %{$params} );
        $fmp->mailresults( %{$params} );
    }
    'ipv4 format 127.0.0.1 does not work as smtp arg';

lives_ok { $fmp = $fmplib->new( %{$main_params} ); }
    'does not live with main params';

