if exist('bt','var') == true
    fclose(bt);
end

%create a bluetooth object
%channel default is 1
bt = Bluetooth('ESP32test',1);
fopen(bt);
disp("Bluetooth conectado!");

sensor1=zeros(100,6);
sensor2=zeros(100,6);
sensor3=zeros(100,6);
sensor4=zeros(100,6);
sensor5=zeros(100,6);

% Comando para iniciar o envio de dados no Arduino
% fprintf(bt,'%c', 'a');
pause(1);

while(true)
    
    fprintf(bt, '%c', '0');
    while(true)
%         if(bt.BytesAvailable > 0)
%             disp(num2str(bt.BytesAvailable));
%         end
        if(bt.BytesAvailable == 12)
            x=fread(bt,6,'int16'); % recebe 6 dados
            vector_data = reshape(x,[],6); % converte matriz de 1 dimens�o para array
            sensor1 = [vector_data; sensor1(1:99,:)];
            break;
        end
        if(bt.BytesAvailable > 12)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    subplot(3,2,1);
    plot(sensor1);
    title('Sensor 1');
%   legend('ax','ay','az','gx','gy','gz');


    fprintf(bt, '%c', '1');
    while(true)
%         if(bt.BytesAvailable > 0)
%             disp(num2str(bt.BytesAvailable));
%         end
        if(bt.BytesAvailable == 12)
            x=fread(bt,6,'int16'); % recebe 6 dados
            vector_data = reshape(x,[],6); % converte matriz de 1 dimens�o para array
            sensor2 = [vector_data; sensor2(1:99,:)];
            break;
        end
        if(bt.BytesAvailable > 12)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    subplot(3,2,2);
    plot(sensor2);
    title('Sensor 2');
    %   legend('ax','ay','az','gx','gy','gz');


    fprintf(bt, '%c', '2');
    while(true)
%         if(bt.BytesAvailable > 0)
%             disp(num2str(bt.BytesAvailable));
%         end
        if(bt.BytesAvailable == 12)
            x=fread(bt,6,'int16'); % recebe 6 dados
            vector_data = reshape(x,[],6); % converte matriz de 1 dimens�o para array
            sensor3 = [vector_data; sensor3(1:99,:)];
            break;
        end
        if(bt.BytesAvailable > 12)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    subplot(3,2,3);
    plot(sensor3);
    title('Sensor 3');
    %   legend('ax','ay','az','gx','gy','gz');


    fprintf(bt, '%c', '3');
    while(true)
%         if(bt.BytesAvailable > 0)
%             disp(num2str(bt.BytesAvailable));
%         end
        if(bt.BytesAvailable == 12)
            x=fread(bt,6,'int16'); % recebe 6 dados
            vector_data = reshape(x,[],6); % converte matriz de 1 dimens�o para array
            sensor4 = [vector_data; sensor4(1:99,:)];
            break;
        end
        if(bt.BytesAvailable > 12)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    subplot(3,2,4);
    plot(sensor4);
    title('Sensor 4');
    %   legend('ax','ay','az','gx','gy','gz');


    fprintf(bt, '%c', '4');
    while(true)
%         if(bt.BytesAvailable > 0)
%             disp(num2str(bt.BytesAvailable));
%         end
        if(bt.BytesAvailable == 12)
            x=fread(bt,6,'int16'); % recebe 6 dados
            vector_data = reshape(x,[],6); % converte matriz de 1 dimens�o para array
            sensor5 = [vector_data; sensor5(1:99,:)];
            break;
        end
        if(bt.BytesAvailable > 12)
            x=fread(bt,bt.BytesAvailable,'int16');
        end
    end
    subplot(3,2,5);
    plot(sensor5);
    title('Sensor 5');
    %   legend('ax','ay','az','gx','gy','gz');

    drawnow
           
end
