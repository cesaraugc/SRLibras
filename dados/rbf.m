X = readtable('dataset_train.csv', 'HeaderLines',1);
X(:,1) = [];
y_train = X(:,31).Variables;
y_train = grp2idx(categorical(y_train));

X = X(:,1:30).Variables;
X = X./16384;
net = newrb(X',ind2vec(y_train'), 0, 1, 270, 1);

X_test = readtable('dataset_test.csv', 'HeaderLines',1);
X_test(:,1) = [];

y_test = X_test(:,31).Variables;
y_test = grp2idx(categorical(y_test));

X_test = X_test(:,1:30).Variables;
X_test = X_test./16384;

res = sim(net, X_test');

acertos = 0;
for i=1:270
    [val, idx] = max(res(:,i));
    if idx == y_test(i)
        acertos = acertos + 1;
    else
        disp("Errou " + num2str(idx));
    end
end

disp("Acertou " + num2str(acertos/270*100) + "%");