function cw6_saveCFG()
global cw6info

fid = fopen('cw7.cfg','w');

fprintf(fid,'%% Comm Port\n%s\n\n%% END\n',cw6info.cfg.commPort);

fclose(fid);
