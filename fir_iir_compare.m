clear; close all; clc;

%% 1. 两种滤波器使用完全相同的要求
fs  = 1000;
fp  = 80;
fst = 120;
Rp  = 0.5;
Rs  = 60;

%% 2. 设计 FIR
dFir = designfilt('lowpassfir', ...
    'PassbandFrequency', fp, ...
    'StopbandFrequency', fst, ...
    'PassbandRipple', Rp, ...
    'StopbandAttenuation', Rs, ...
    'SampleRate', fs);

bFir = dFir.Coefficients;
nFir = numel(bFir) - 1;

%% 3. 设计 Butterworth IIR
Wp = fp  / (fs/2);
Ws = fst / (fs/2);

[Niir, WnIir] = buttord(Wp, Ws, Rp, Rs);
[bIir, aIir] = butter(Niir, WnIir);

fprintf('FIR：%d 阶，%d 个抽头\n', nFir, numel(bFir));
fprintf('IIR：%d 阶，b 有 %d 项，a 有 %d 项\n', ...
        Niir, numel(bIir), numel(aIir));

%% 4. 计算幅频、相位和群延迟
Nfft = 8192;

[HF, f]    = freqz(bFir, 1, Nfft, fs);
[HI, ~]    = freqz(bIir, aIir, Nfft, fs);

[gF, ~]    = grpdelay(bFir, 1, Nfft, fs);
[gI, ~]    = grpdelay(bIir, aIir, Nfft, fs);

magF = 20*log10(abs(HF));
magI = 20*log10(abs(HI));

% angle 返回弧度，unwrap 去掉 ±180° 的突然跳变
phaseF = unwrap(angle(HF)) * 180/pi;
phaseI = unwrap(angle(HI)) * 180/pi;

%% 5. 计算是否满足指标
idxP = f <= fp;
idxS = f >= fst;

fprintf('\nFIR 通带最大/最小：%.3f / %.3f dB\n', ...
    max(magF(idxP)), min(magF(idxP)));
fprintf('IIR 通带最大/最小：%.3f / %.3f dB\n', ...
    max(magI(idxP)), min(magI(idxP)));

fprintf('\nFIR 阻带最差：%.2f dB\n', max(magF(idxS)));
fprintf('IIR 阻带最差：%.2f dB\n', max(magI(idxS)));

%% 6. 图 1：幅频比较
figure(1);
plot(f, magF, 'LineWidth', 1.3);
hold on;
plot(f, magI, '--', 'LineWidth', 1.3);
xline(fp,  'k:');
xline(fst, 'k:');
yline(-Rs, 'r:');
xlim([0 200]);
ylim([-100 5]);
xlabel('频率（Hz）');
ylabel('幅度（dB）');
title('相同指标下：FIR 与 IIR 的幅频比较');
legend('FIR', 'Butterworth IIR', 'Location', 'southwest');
grid on;

%% 7. 图 2：只看通带内的相位
figure(2);
plot(f, phaseF, 'LineWidth', 1.3);
hold on;
plot(f, phaseI, '--', 'LineWidth', 1.3);
xlim([0 fp]);
xlabel('频率（Hz）');
ylabel('相位（度）');
title('通带相位：FIR 与 IIR');
legend('FIR', 'Butterworth IIR', 'Location', 'southwest');
grid on;

%% 8. 图 3：只看通带内的群延迟
figure(3);
plot(f, gF, 'LineWidth', 1.3);
hold on;
plot(f, gI, '--', 'LineWidth', 1.3);
xlim([0 fp]);
xlabel('频率（Hz）');
ylabel('群延迟（采样点）');
title('通带群延迟：FIR 与 IIR');
legend('FIR', 'Butterworth IIR', 'Location', 'northwest');
grid on;

fprintf('\nFIR 通带平均群延迟 = %.2f 个采样点\n', mean(gF(idxP)));
fprintf('IIR 通带群延迟范围 = %.2f 到 %.2f 个采样点\n', ...
    min(gI(idxP)), max(gI(idxP)));