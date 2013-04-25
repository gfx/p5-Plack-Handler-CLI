requires 'Any::Moose';
requires 'Plack', '0.99';
requires 'URI::Escape';
requires 'perl', '5.008001';
recommends 'URI::Escape::XS', '0.07';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'HTTP::Request::AsCGI';
    requires 'Test::More', '0.88';
    requires 'Test::Requires';
};
