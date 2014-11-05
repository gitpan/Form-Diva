use strict;
use warnings;

package DBIx::Class::Row;

sub new {
    my $class = shift;
    my $self = { @_, data => { fname => 'mocdbic', purpose => 'testing' } };
    bless $self, $class;
    return $self;
}

sub get_inflated_columns {
    my $self = shift;
    return %{ $self->{data} };
}

package TestThing;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Form::Diva');

my $notdbic = {
    fname   => 'realhash',
    purpose => 'comparison',
};

my $mocdbic = DBIx::Class::Row->new;

isa_ok( $mocdbic, 'DBIx::Class::Row',
    'moc dbic object looks like a dbix::class object' );
my %inflated = $mocdbic->get_inflated_columns();
is( $inflated{fname}, 'mocdbic',
    'moc object returns data for ->get_inflated_columns' );

my $rehashnotdbic = Form::Diva::_checkdatadbic($notdbic);
is( eq_hash( $rehashnotdbic, $notdbic ),
    1, "_checkdatadbic returns the original with a plain hashref" );

my $rehashdbic = Form::Diva::_checkdatadbic($mocdbic);
is( eq_hash( $rehashdbic, { fname => 'mocdbic', purpose => 'testing' } ),
    1, "_checkdatadbic returns the data with a dbic row" );

is( Form::Diva::_checkdatadbic( [qw / not valid data /] ),
    undef, 'sending an array_ref to _checkdatadbic returns undef' );

my $diva = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name   => 'diva1',
    form        => [ { n => 'fname' }, { name => 'purpose' }, ],
);

my $results_plain = $diva->generate($notdbic);

like( $results_plain->[1]{label},
    qr/for="formdiva_purpose"/, 'plain hash generates label for purpose' );
like(
    $results_plain->[0]{input},
    qr/ value="realhash"/,
    'plain hash generates value fname field'
);
like( $results_plain->[1]{input},
    qr/comparison"/,
    'plain hash generates input tag with value of purpose field' );

my $results_dbic = $diva->generate($mocdbic);
like( $results_dbic->[1]{label},
    qr/for="formdiva_purpose"/, 'dbic result generates label for purpose' );
like( $results_dbic->[0]{input},
    qr/value="mocdbic"/, 'dbic result generates value for fname field' );
like( $results_dbic->[1]{input},
    qr/testing"/,
    'dbic result generates input tag with value of purpose field' );

done_testing();
