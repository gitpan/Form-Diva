# id is calculated in multiple places, this test makes sure it is
# done as documented and the same.

use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use_ok('Form::Diva');

my $diva1 = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name   => 'diva1',
    form        => [
        { n => 'name', t => 'text', p => 'Your Name', l => 'Full Name' },
        { name => 'phone', type => 'tel', extra => 'required' },
        {qw / n email t email l Email c form-email id eml/},
        { name => 'our_id', type => 'number', extra => 'disabled' },
    ],
    hidden => [
        { n => 'secret' },
        { n => 'hush', default => 'very secret' },
        {   n     => 'mystery',
            id    => 'mystery_site_url',
            extra => 'custom="bizarre"',
            type  => "url"
        }
    ],
);

my $id_phone   = 'formdiva_phone';
my $id_email   = 'eml';
my $id_secret  = 'formdiva_secret';
my $id_mystery = 'mystery_site_url';

my $generated = $diva1->generate;
my $hidden    = $diva1->hidden;
my $datavalues     = $diva1->datavalues;

like( $generated->[1]{input},
    qr/id="$id_phone"/,
    "generate returned input with correct id for phone $id_phone." );
like( $generated->[2]{input},
    qr/id="$id_email"/,
    "generate returned input with correct id for email $id_email." );

is( $datavalues->[1]{id}, $id_phone,
    "datavalues returned data with correct id for phone $id_phone." );
is( $datavalues->[2]{id}, $id_email,
    "datavalues returned data with correct id for email $id_email." );

like( $hidden, qr/id="$id_secret"/,
    "hidden returned correct id for secret $id_secret." );
like( $hidden, qr/id="$id_mystery"/,
    "hidden returned correct id for mystery $id_mystery." );

foreach my $case (qw /select radio checkbox/) {
    my $diva = Form::Diva->new(
        label_class => 'label',
        input_class => 'input',
        form        => [
            { n => 'hasnt', t => $case, v => [qw /abc def xyz/] },
            {   n  => 'has',
                t  => $case,
                id => 'zmyxfd',
                v  => [qw /abc def xyz/]
            },
        ],
    );
    my $generated = $diva->generate;
    my $datavalues     = $diva->datavalues;
    like( $generated->[0]{input},
        qr/id="formdiva_hasnt_xyz"/,
        "$case input has autogenerated id: formdiva_hasnt_xyz" );
    like( $generated->[1]{input},
        qr/id="zmyxfd_def"/,
        "$case input option generated from preset id: zmyxfd_def" );
    if ( $case eq 'select' ) {
        like( $generated->[0]{input},
            qr/id="formdiva_hasnt"/,
            "$case outer select tag autogenerated id: formdiva_hasnt" );
        like( $generated->[1]{input},
            qr/id="zmyxfd"/,
            "$case outer select tag generated from preset id: zmyxfd" );
    }
    is( $datavalues->[0]{id}, "formdiva_hasnt",
        "$case datavalues returned generated id formdiva_hasntz" );
    is( $datavalues->[1]{id}, "zmyxfd", "$case datavalues returned preset id zmyxfd" );
}

done_testing;
