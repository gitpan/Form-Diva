#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use 5.014;
use Storable qw(dclone);

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name => 'diva1',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        { name => 'phone', type => 'tel', extra => 'required' },
        {qw / n email t email l Email c form-email placeholder doormat/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
    ],
);

my $newform = &Form::Diva::_expandshortcuts( $diva1->{form} );
is( $newform->[0]{p},     undef,       'record 0 p is undef' );
is( $newform->[0]{label}, 'Full Name', 'record 0 label is Full Name' );
is( $newform->[0]{placeholder},
    'Your Name', 'value from p got moved to placeholder' );
is( $newform->[2]{placeholder},
    'doormat', 'placeholder set for the email field too' );
is( $newform->[3]{name}, 'our_id', 'last record in test is named our_id' );
is( $newform->[3]{extra},
    'disabled', 'last record extra field has value disabled' );


done_testing();
