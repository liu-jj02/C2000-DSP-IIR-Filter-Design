clear; close all; clc;

%% 指标
fs  = 1000;
fp  = 80;
fst = 120;
Rp  = 0.5;
Rs  = 60;

%% 归一化到 Nyquist 频率
Wp = fp  / (fs/2);
Ws = fst / (fs/2);

%% 求满足指标的最低 Butterworth 阶数
[Nb, WnB] = buttord(Wp, Ws, Rp, Rs);

%% 生成数字 Butterworth 滤波器
[b, a] = butter(Nb, WnB);

fprintf('Butterworth 阶数 = %d\n', Nb);
fprintf('b 系数个数 = %d\n', numel(b));
fprintf('a 系数个数 = %d\n', numel(a));

%% 求频率响应和群延迟
[Hb, f]   = freqz(b, a, 4096, fs);
[gdB, fg] = grpdelay(b, a, 4096, fs);

%% 图 1：幅频响应
figure;
subplot(2,1,1);
plot(f, 20*log10(abs(Hb)), 'LineWidth', 1.2);
xline(fp,  'k:');
xline(fst, 'k:');
yline(-Rs, 'r:');
xlim([0 250]);
ylim([-100 5]);
xlabel('频率 (Hz)');
ylabel('|H| (dB)');
title(sprintf('Butterworth 低通：%d 阶', Nb));
grid on;

%% 图 1 下半部分：群延迟
subplot(2,1,2);
plot(fg, gdB, 'LineWidth', 1.2);
xlim([0 fp]);
xlabel('频率 (Hz)');
ylabel('群延迟（样本）');
title('通带内的群延迟');
grid on;

magB = 20*log10(abs(Hb));

%% 统计通带实际变化
idxP = f <= 80;
passMax = max(magB(idxP));
passMin = min(magB(idxP));

fprintf('通带最大增益 = %.4f dB\n', passMax);
fprintf('通带最小增益 = %.4f dB\n', passMin);
fprintf('通带实际变化 = %.4f dB\n', passMax - passMin);

%% 统计阻带最差位置
idxS = f >= 120;
stopWorst = max(magB(idxS));

fprintf('120 Hz 以上最差衰减 = %.2f dB\n', stopWorst);

%% 只放大 0–80 Hz
figure;
plot(f, magB, 'LineWidth', 1.5);
yline(0,   'k-');
yline(-0.5,'r:');
xlim([0 80]);
ylim([-0.8 0.1]);
xlabel('频率 (Hz)');
ylabel('|H| (dB)');
title('放大后的通带：0–80 Hz');
grid on;

%% 把高阶 [b,a] 拆成 SOS
[sos, g] = tf2sos(b, a);

fprintf('SOS 数组大小：%d 行，%d 列\n', ...
    size(sos,1), size(sos,2));

fprintf('SOS 整体增益 g = %.6f\n', g);

disp('前几个二阶节：');
disp(sos(1:min(3,size(sos,1)), :));

xImp = [1, zeros(1, 999)];

%% 直接用高阶 b、a
yDirect = filter(b, a, xImp);

%% 用 SOS 级联
ySOS = sosfilt(sos, g * xImp);

fprintf('两种实现最大差异 = %.3e\n', ...
    max(abs(yDirect - ySOS)));

%% 用相同指标设计 Chebyshev I
[Nc, WnC] = cheb1ord(Wp, Ws, Rp, Rs);
[bc, ac]   = cheby1(Nc, Rp, WnC);

fprintf('Chebyshev I 阶数 = %d\n', Nc);
fprintf('Chebyshev I 的 b 系数个数 = %d\n', numel(bc));
fprintf('Chebyshev I 的 a 系数个数 = %d\n', numel(ac));

[Hc, f] = freqz(bc, ac, 4096, fs);

%% 两种 IIR 的幅频对比
figure;
plot(f, 20*log10(abs(Hb)), 'LineWidth', 1.3); hold on;
plot(f, 20*log10(abs(Hc)), '--', 'LineWidth', 1.3);

xline(80,  'k:');
xline(120, 'k:');
yline(-60, 'r:');

xlim([0 200]);
ylim([-120 2]);
xlabel('频率 (Hz)');
ylabel('|H| (dB)');
legend('Butterworth', 'Chebyshev I', 'Location', 'southwest');
title('相同指标下：Butterworth vs Chebyshev I');
grid on;

magC = 20*log10(abs(Hc));

idxC = f <= 80;

figure;
plot(f, magC, 'LineWidth', 1.3);
yline(0,   'k-');
yline(-0.5,'r:');
xlim([0 80]);
ylim([-0.7 0.1]);
xlabel('频率 (Hz)');
ylabel('|H| (dB)');
title('Chebyshev I 通带：可以看到波纹');
grid on;