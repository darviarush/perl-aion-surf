requires 'perl', '5.22.0';

on 'develop' => sub {
    requires 'Minilla', 'v3.1.19';
};

on 'test' => sub {
	requires 'Liveman',
		git => 'https://github.com/darviarush/perl-liveman.git',
		ref => 'master';
    requires 'Aion::Carp',
        git => 'https://github.com/darviarush/perl-aion-carp.git',
        ref => 'master';
    requires 'Data::Printer', '1.000004';
};

requires 'common::sense', '3.75';
requires 'Aion',
    git => 'https://github.com/darviarush/perl-aion.git',
    ref => 'master';
