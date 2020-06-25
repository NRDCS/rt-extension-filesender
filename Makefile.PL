BEGIN { push @INC, '.' }
use inc::Module::Install;

RTx     'RT-Extension-Filesender';
license 'gpl_2';
repository 'https://github.com/andrius.kulbis/rt-extension-filesender';

requires_rt '4.4.0';
rt_too_new '5.2.0';

requires 'JSON';
requires 'LWP::UserAgent';
requires 'Digest::SHA';
requires 'URI::Split';

auto_install();

sign;
WriteAll;