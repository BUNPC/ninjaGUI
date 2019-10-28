function cw6_cfgFile_updateCom( comPort )

if exist('cw6.cfg','file')
    fid = fopen( 'cw6.cfg', 'r' );
    fidO = fopen( 'cw6.tmp', 'w' );
    
    sline = fgetl( fid );
    if sline==-1
        flag = 1;
    else
        flag = 0;
    end
    while flag==0
        flag2 = 0;
        if length(sline)>3
            if strcmpi( sline(1:3), 'COM' )
                fprintf( fidO, '%s\n', comPort );
                flag2 = 1;
            end
        end
        if flag2==0
            fprintf( fidO, '%s\n', sline );
        end
        sline = fgetl( fid );
        if sline==-1
            flag = 1;
        end
    end
    
    fclose( fid );
    fclose( fidO );
    
    movefile('cw6.tmp', 'cw6.cfg' );
else
    fid = fopen( 'cw6.cfg', 'w' );
    fprintf( fid, '%% Comm Port\n' );
    fprintf( fid, '%s\n', comPort );
    fprintf( fid, '\n\n%% END\n' );
    fclose(fid);
end

    

