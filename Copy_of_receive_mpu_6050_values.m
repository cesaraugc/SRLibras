if exist('bt','var') == true
    fclose(bt);
end

%create a bluetooth object
%HC-05 channel default is 1
bt = Bluetooth('HC-05',1);
fopen(bt);
disp("Bluetooth conectado!");

sensor1=zeros(100,6);
sensor2=zeros(100,6);
sensor3=zeros(100,6);
sensor4=zeros(100,6);
sensor5=zeros(100,6);

% Comando para iniciar o envio de dados no Arduino
fprintf(bt,'%c', 'a');

while(true)
    
    if(bt.BytesAvailable > 0)
%         [x, count, msg]=fread(bt,bt.BytesAvailable,'int16'); % recebe 5 dados
%         disp(x);

        x=scanstr(bt, ',');
        vector_data = reshape(cell2mat(x),1,[]); % converte matriz de 1 dimensão para array
        sensor1 = [vector_data; sensor1(1:99,:)];
%         subplot(3,2,1);
%         plot(sensor1);
% %         legend('ax','ay','az','gx','gy','gz');
%         title('Sensor 1');

        x=scanstr(bt, ',');
        vector_data = reshape(cell2mat(x),1,[]); % converte matriz de 1 dimensão para array
%         sensor2= [sensor2; vector_data]
        sensor2 = [vector_data; sensor2(1:99,:)];
%         subplot(3,2,2);
%         plot(sensor2);
% %         legend('ax','ay','az','gx','gy','gz');
%         title('Sensor 2');

        x=scanstr(bt, ',');
        vector_data = reshape(cell2mat(x),1,[]); % converte matriz de 1 dimensão para array
        sensor3= [vector_data; sensor3(1:99,:)];
%         subplot(3,2,3);
%         plot(sensor3);
% %         legend('ax','ay','az','gx','gy','gz');
%         title('Sensor 3');

        x=scanstr(bt, ',');
        vector_data = reshape(cell2mat(x),1,[]); % converte matriz de 1 dimensão para array
        sensor4= [vector_data;sensor4(1:99,:)];
        subplot(3,2,4);
        plot(sensor4);
%         legend('ax','ay','az','gx','gy','gz');
%         title('Sensor 4');

        x=scanstr(bt, ',');
        vector_data = reshape(cell2mat(x),1,[]); % converte matriz de 1 dimensão para array
        sensor5= [vector_data; sensor5(1:99,:)];
%         subplot(3,2,5);
%         plot(sensor5);
% %         legend('ax','ay','az','gx','gy','gz');
%         title('Sensor 5');

        drawnow
       
    end
end
fclose(bt);
