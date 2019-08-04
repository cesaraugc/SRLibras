if exist('bt','var') == true
    fclose(bt);
end

%create a bluetooth object
%channel default is 1
bt = Bluetooth('ESP32test',1);
fopen(bt);
disp("Bluetooth conectado!");

tempo_captura = 1; % segundos

% i=1;
% iniciar = tic;
while(true)
%     if toc(iniciar)>tempo_captura
%         break;
%     end
    fprintf(bt, '%c', 'a');
    comun = tic;
    while(true)
        if(bt.BytesAvailable == 10)
            x=fread(bt,10,'uint8');
            toc(comun);
            break;
        end
    end
    
end