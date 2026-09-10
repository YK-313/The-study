%% ① 数学的な限界値を直接計算して確認する
limit_value = log(realmax);
fprintf('数学的なオーバーフロー限界値: %.15f\n', limit_value);

%% ② 境界値の「直前」と「直後」でexp(x)を計算してみる
x_safe  = 709.78271;  % 限界の手前
x_crash = 709.78272;  % 限界の直後

val_safe  = exp(x_safe);
val_crash = exp(x_crash);

disp('--------------------------------------------------')
fprintf('x = %.5f のとき (限界直前): exp(x) = %g\n', x_safe, val_safe);
fprintf('x = %.5f のとき (限界直後): exp(x) = %g\n', x_crash, val_crash);

%% ③ 限界を極限まで攻める（eps関数による確認）
% 限界値そのもの
disp('--------------------------------------------------')
fprintf('exp(limit_value)              = %g\n', exp(limit_value)); 
% 限界値に計算機の最小単位(eps)を足すと即座にInfになる
fprintf('exp(limit_value + eps(709.78)) = %g\n', exp(limit_value + eps(limit_value)));