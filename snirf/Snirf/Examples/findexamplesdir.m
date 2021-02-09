function rootdirexamples = findexamplesdir()

rootdir = fileparts(which('SnirfClass.m'));
rootdirexamples = [rootdir, '/Examples/'];
rootdirexamples(rootdirexamples=='\') = '/';