if exist('bt','var') == true
    fclose(bt);
end

%create a bluetooth object
%channel default is 1
bt = Bluetooth('ESP32test',1);
fopen(bt);
disp("Bluetooth conectado!");

sensor1=zeros(30,100);
% sensor1 = [];
% sensor2=zeros(100,6);
% sensor3=zeros(100,6);
% sensor4=zeros(100,6);
% sensor5=zeros(100,6);

pause(1);
tempo_captura = 1; % segundos

i=1;
iniciar = tic;
while(true)
    if toc(iniciar)>tempo_captura
        break;
    end
    fprintf(bt, '%c', 't');
    comun = tic;
    while(true)
        % 2*6*5=60 bytes
        
        if(bt.BytesAvailable == 60)
            toc(comun);
            x=fread(bt,30,'int16'); % recebe 6*5 dados
            % vector_data = reshape(x,[],30); % converte matriz de 1 dimensao para array
            sensor1(:,i) = x;
            i = i + 1;
            break;
        % Limpa o buffer em caso de algum problema de comunicacao
        elseif(bt.BytesAvailable > 60)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    
end