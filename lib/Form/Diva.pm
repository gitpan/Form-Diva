use strict;
use warnings;
no warnings 'uninitialized';

package Form::Diva;
$Form::Diva::VERSION = '0.05'; # TRIAL
# ABSTRACT: Generate HTML5 form label and input fields

use Storable qw(dclone);

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->{class} = $class;
    unless ( $self->{input_class} ) { die 'input_class is required.' }
    unless ( $self->{label_class} ) { die 'label_class is required.' }
    ( $self->{FormMap}, $self->{FormHash} )
        = &_expandshortcuts( $self->{form} );
    return $self;
}

sub clone {
    my $self = shift ;
    my $args = shift ;
    my $new = {};
    my $class = 'Form::Diva';
    $new->{FormHash}    = dclone $self->{FormHash};
    $new->{input_class} = $args->{input_class} || $self->{input_class};
    $new->{label_class} = $args->{label_class} || $self->{label_class};
    $new->{form_name}   = $args->{form_name}   || $self->{form_name};
    if( $args->{neworder} ){
            my @reordered = map { $new->{FormHash}->{$_} } @{$args->{neworder}};
            $new->{FormMap} = \@reordered ;
        }
    else { $new->{FormMap} = dclone $self->{FormMap} ; }        
    bless $new, $class ;
    return $new ;
}

# so far diva hasn't needed the form name
# sub form_name {
#     my $self = shift ;
#     return $self->{form_name};
# }

sub input_class {
    my $self = shift ;
    return $self->{input_class};
}

sub label_class {
    my $self = shift ;
    return $self->{label_class};
}

# specification calls for single letter shortcuts on all fields
# these all need to expand to the long form.
sub _expandshortcuts {
    my %DivaShortMap = (
        qw /
            n name t type i id e extra x extra l label p placeholder
            d default v values c class /
    );
    my %DivaLongMap = map { $DivaShortMap{$_}, $_ } keys(%DivaShortMap);
    my $FormHash    = {};
    my $FormMap     = shift;
    foreach my $formfield ( @{$FormMap} ) {
        foreach my $tag ( keys %{$formfield} ) {
            if ( $DivaShortMap{$tag} ) {
                $formfield->{ $DivaShortMap{$tag} }
                    = delete $formfield->{$tag};
            }
        }
        unless ( $formfield->{type} ) { $formfield->{type} = 'text' }
        unless ( $formfield->{name} ) { die "fields must have names" }
        $FormHash->{ $formfield->{name} } = $formfield;
    }
    return ( $FormMap, $FormHash );
}

# given a field returns either the default field class="string"
# or the field specific one
sub _class_input {
    my $self   = shift;
    my $field  = shift;
    my $fclass = $field->{class} || '';
    if   ($fclass) { return qq!class="$fclass"! }
    else           { return qq!class="$self->{input_class}"! }
}

sub _field_bits {
    my $self      = shift;
    my $field_ref = shift;
    my $data      = shift;
    my %in        = %{$field_ref};
    my %out       = ();
    my $fname     = $in{name};
    $out{extra} = $in{extra};    # extra is taken literally
    $out{input_class} = $self->_class_input($field_ref);
    $out{name}        = qq!name="$in{name}"!;
    $out{id}          = $in{id} ? qq!id="$in{id}"! : qq!id="$in{name}"!;

    if ( lc( $in{type} ) eq 'textarea' ) {
        $out{type}     = 'textarea';
        $out{textarea} = 1;
    }
    else {
        $out{type}     = qq!type="$in{type}"!;
        $out{textarea} = 0;
    }
    if ($data) {
        $out{placeholder} = '';
        $out{rawvalue} = $data->{$fname} || '';
    }
    else {
        if ( $in{placeholder} ) {
            $out{placeholder} = qq!placeholder="$in{placeholder}"!;
        }
        else { $out{placeholder} = '' }
        if   ( $in{default} ) { $out{rawvalue} = $in{default}; }
        else                  { $out{rawvalue} = '' }
    }
    $out{value} = qq!value="$out{rawvalue}"!;
    return %out;
}

sub _label {
    my $self        = shift;
    my $field       = shift;
    my $fname       = $field->{name};
    my $label_class = $self->{label_class};
    my $label_tag   = $field->{label} || ucfirst($fname);
    return qq|<LABEL for="$fname" class="$label_class">|
        . qq|$label_tag</LABEL>|;
}

sub _input {
    my $self  = shift;
    my $field = shift;
    my $data  = shift;
    my %B     = $self->_field_bits( $field, $data );
    my $input = '';
    if ( $B{textarea} ) {
        $input = qq|<TEXTAREA $B{name} $B{id}
        $B{input_class} $B{placeholder} $B{extra} >$B{rawvalue}</TEXTAREA>|;
    }
    else {
        $input .= qq|<INPUT $B{type} $B{name} $B{id}
        $B{input_class} $B{placeholder} $B{extra} $B{value} >|;
    }
    $input =~ s/\s+/ /g;     # remove extra whitespace.
    $input =~ s/\s+>/>/g;    # cleanup space before closing >
    return $input;
}

# Note need to check default field and disable disabled fields
# this needs to be implemented after data is being handled because
# default is irrelevant if there is data.

sub _radiocheck {    # field, input_class, data;
    my $self           = shift;
    my $field          = shift;
    my $data           = shift;
    my $replace_fields = shift;
    my $output         = '';
    my $input_class    = $self->_class_input($field);
    my $extra          = $field->{extra} || "";
    my $default        = $field->{default}
        ? do {
        if   ($data) {undef}
        else         { $field->{default} }
        }
        : undef;
    my @values
        = $replace_fields
        ? @{$replace_fields}
        : @{ $field->{values} };    
    foreach my $val ( @values ) {
        my ( $value, $v_lab ) = ( split( /\:/, $val ), $val );
        my $checked = '';
        if    ( $data eq $value )    { $checked = 'checked ' }
        elsif ( $default eq $value ) { $checked = 'checked ' }
        $output
            .= qq!<input type="$field->{type}" $input_class $extra name="$field->{name}" value="$value" $checked>$v_lab<br>\n!;
    }
    return $output;
}

sub _select {    # field, input_class, data;
    my $self           = shift;
    my $field          = shift;
    my $data           = shift;
    my $replace_fields = shift;
    my $class          = $self->_class_input($field);
    my $extra          = $field->{extra} || "";
    my $id = $field->{id} ? qq!id="$field->{id}"! : qq!id="$field->{name}"!;
    my @values
        = $replace_fields
        ? @{$replace_fields}
        : @{ $field->{values} };
    my $default = $field->{default}
        ? do {
        if   ($data) {undef}
        else         { $field->{default} }
        }
        : undef;
    my $output = qq|<SELECT name="$field->{name}" $id $extra $class>\n|;
    foreach my $val (@values) {
        my ( $value, $v_lab ) = ( split( /\:/, $val ), $val );
        my $selected = '';
        if    ( $data eq $value )    { $selected = 'selected ' }
        elsif ( $default eq $value ) { $selected = 'selected ' }
        $output .= qq| <option value="$value" $selected>$v_lab</option>\n|;
    }
    $output .= '</SELECT>';
    return $output;
}

sub generate {
    my $self    = shift;
    my $data    = shift;
    my $overide = shift;
    unless ( keys %{$data} ) { $data = undef }
    my @generated = ();
    foreach my $field ( @{ $self->{FormMap} } ) {
        my $input = undef;
        if ( $field->{type} eq 'radio' || $field->{type} eq 'checkbox' ) {
            $input = $self->_radiocheck(
                $field,
                $data->{ $field->{name} },
                $overide->{ $field->{name} },
            );
        }
        elsif ( $field->{type} eq 'select' || $field->{type} eq 'datalist' ) {
            $input = $self->_select(
                $field,
                $data->{ $field->{name} },
                $overide->{ $field->{name} },
            );
        }
        else {
            $input = $self->_input( $field, $data );
        }
        $input =~ s/  +/ /g;     # remove extra whitespace.
        $input =~ s/\s+>/>/g;    # cleanup space before closing >
        push @generated,
            {
            label => $self->_label($field),
            input => $input
            };
    }
    return \@generated;
}

1;
