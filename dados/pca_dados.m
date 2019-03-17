X = readtable('dataset_total.csv', 'HeaderLines',1);
X(:,1) = [];
y_tmp = X(:,31).Variables;
% y = grp2idx(categorical(y));
y = strings(size(y_tmp));
for i=1:size(y_tmp)
    y(i) = string(y_tmp(i));
end

X = X(:,1:30).Variables;
X = X./16384;

[W, pc] = pca(X(1:27000,:));
pc = pc'; W = W';

letras = ["r", "u", "v"];

group1 = pc(:,y==letras(1)); 
group2 = pc(:,y==letras(2));
group3 = pc(:,y==letras(3));

figure(1);
scatter3(group1(1,:), group1(2,:), group1(3,:), 'r', 'filled');
hold on
scatter3(group2(1,:), group2(2,:), group2(3,:), 'b', 'filled');
hold on
scatter3(group3(1,:), group3(2,:), group3(3,:), 'g', 'filled');
hold off
grid on
legend(letras(1), letras(2), letras(3))
xlabel('Principal Component 1')
ylabel('Principal Component 2')
zlabel('Principal Component 3')