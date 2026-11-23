clear; close all; clc;

%% 基础参数
fs = 1000;             % 采样率
N  = 61;               % 观察 61 个样本

%% 构造一个冲激：只有第一个样本等于 1
imp = [1, zeros(1, N-1)];

%% y[n] = x[n] + 0.9*y[n-1]
%% MATLAB 的 filter 写成：
%% a(1)*y[n] = b(1)*x[n] - a(2)*y[n-1] ...
coefA = 0.9;
b     = 1;
aDen  = [1, -coefA];

h = filter(b, aDen, imp);

%% 极点与稳定性
p = roots(aDen);
fprintf('极点 = %.4f\n', real(p));
fprintf('极点模值 = %.4f\n', abs(p));

fprintf('\n前 11 个冲激响应值：\n');
disp(h(1:11));

%% 图 1：冲激响应
figure(1);
stem(0:N-1, h, 'filled');
xlabel('样本 n');
ylabel('h[n]');
title('一阶 IIR 的冲激响应：0.9^n');
grid on;

%% 图 2：阶跃响应
step = ones(1, N);
yStep = filter(b, aDen, step);

figure(2);
plot(0:N-1, yStep, 'o-', 'LineWidth', 1.2);
xlabel('样本 n');
ylabel('y[n]');
title('一阶 IIR 的阶跃响应');
grid on;

%% 图 3：幅频和群延迟
[H, f]    = freqz(b, aDen, 1024, fs);
[gd, fg]  = grpdelay(b, aDen, 1024, fs);

figure(3);
subplot(2,1,1);
plot(f, 20*log10(abs(H)), 'LineWidth', 1.2);
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title('一阶 IIR 的幅频响应');
grid on;

subplot(2,1,2);
plot(fg, gd, 'LineWidth', 1.2);
xlabel('频率 (Hz)');
ylabel('群延迟（样本）');
title('群延迟随频率变化');
grid on;