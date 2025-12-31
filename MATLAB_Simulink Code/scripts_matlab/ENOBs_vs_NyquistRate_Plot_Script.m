clearvars; close all; clc;

dataVarName = 'digital_out';
quantizerBits = 24;
applyQuantizeBeforeDecimation = true;
nyquist_rates = [100 200 500 800 1000 1200 1500 1750 2000 3000 3500 4000];
saveFigure = true;
figureFilename = 'ENOB_vs_Nyquist.png';
maxFFTpoints = 2^18;

floor_local_window_frac = 0.001;
floor_global_guard_frac = 0.005;
floor_scale = 0.7;
nbins_signal = 3;

if evalin('base', ['exist(''' dataVarName ''',''var'')'])
    raw = evalin('base', dataVarName);
else
    error('Variable not found');
end

time = [];
data = [];

if isa(raw,'timeseries')
    time = raw.Time(:); data = raw.Data(:);
elseif istimetable(raw)
    time = seconds(raw.Properties.RowTimes - raw.Properties.RowTimes(1)); data = raw{:,1};
elseif isstruct(raw)
    if isfield(raw,'time') && isfield(raw,'signals')
        time = raw.time(:); s = raw.signals;
        if isstruct(s) && isfield(s,'values'), data = s.values(:); else, data = s(:); end
    elseif isfield(raw,'Time') && isfield(raw,'Data')
        time = raw.Time(:); data = raw.Data(:);
    else
        f = fieldnames(raw);
        for i=1:numel(f)
            val = raw.(f{i});
            if isnumeric(val) && isvector(val), data = val(:); end
            if isfield(raw,'time') && isempty(time), time = raw.time(:); end
        end
    end
elseif isnumeric(raw) && isvector(raw)
    data = raw(:);
    if evalin('base','exist(''time'',''var'')')
        time = evalin('base','time'); time = time(:);
    elseif evalin('base','exist(''t'',''var'')')
        time = evalin('base','t'); time = time(:);
    else
        time = (0:numel(data)-1)';
    end
else
    error('Bad data format');
end

if numel(time) ~= numel(data)
    N = min(numel(time), numel(data)); time = time(1:N); data = data(1:N);
end

if isdatetime(time)
    time = seconds(time - time(1));
end

dt = mean(diff(time));
Fs_mod = 1/dt;

if applyQuantizeBeforeDecimation && quantizerBits < 64
    xmax = max(abs(data)); if xmax == 0, xmax = 1; end
    Qlevels = 2^quantizerBits;
    qstep = 2*xmax / Qlevels;
    data = qstep * ( floor(data / qstep) + 0.5 );
end

ENOBs = zeros(size(nyquist_rates));
SNRs_dB = zeros(size(nyquist_rates));
N_out_samples = zeros(size(nyquist_rates));

function [SNR_dB, sigFreq, fVec, PSD] = estimate_snr_fft_noise_flooring(x, Fs, floor_local_window_frac, floor_global_guard_frac, floor_scale, nbins_signal)
    N = numel(x);
    w = hann(N);
    xw = (x - mean(x)) .* w;
    X = fft(xw);
    half = floor(N/2);
    X = X(1:half);
    fVec = (0:half-1)' * (Fs / N);
    PSD = (abs(X).^2) / (sum(w.^2));
    PSD_noDC = PSD; PSD_noDC(1) = 0;
    [~, idx_peak] = max(PSD_noDC);
    sigFreq = fVec(idx_peak);
    guard_bins = max(3, round(floor_global_guard_frac * numel(PSD)));
    local_window = max(5, round(floor_local_window_frac * numel(PSD)));
    if mod(local_window,2)==0, local_window = local_window + 1; end
    idx_lo = max(1, idx_peak - guard_bins);
    idx_hi = min(numel(PSD), idx_peak + guard_bins);
    mask = true(size(PSD)); mask(idx_lo:idx_hi) = false;
    global_median = median(PSD(mask));
    local_med = movmedian(PSD, local_window);
    noise_floor = max(global_median, floor_scale * local_med);
    sig_range = max(1, idx_peak-nbins_signal):min(numel(PSD), idx_peak+nbins_signal);
    PSD_noise_only = PSD; PSD_noise_only(sig_range) = noise_floor(sig_range);
    sig_power = sum(PSD(sig_range));
    noise_power = sum(PSD_noise_only);
    if noise_power <= 0, SNR_dB = 100;
    else, SNR = sig_power / noise_power; SNR_dB = 10*log10(SNR);
    end
end

for k = 1:numel(nyquist_rates)
    Fs_out = nyquist_rates(k);
    dec_factor = round(Fs_mod / Fs_out);

    if dec_factor < 1
        [p_approx,q_approx] = rat(Fs_out / Fs_mod, 1e-6);
        y = resample(data, p_approx, q_approx);
        Fs_y = Fs_mod * p_approx / q_approx;
    else
        try
            y = decimate(data, dec_factor); Fs_y = Fs_mod / dec_factor;
        catch
            y = resample(data, 1, dec_factor); Fs_y = Fs_mod / dec_factor;
        end
    end

    N_out_samples(k) = numel(y);
    y = y - mean(y);
    Nfft = numel(y);
    if Nfft > maxFFTpoints, y = y(1:maxFFTpoints); Nfft = maxFFTpoints; end

    [SNR_dB, sigFreq, ~, ~] = estimate_snr_fft_noise_flooring(y, Fs_y, floor_local_window_frac, floor_global_guard_frac, floor_scale, nbins_signal);
    SNRs_dB(k) = SNR_dB;
    ENOBs(k) = (SNR_dB - 1.76)/6.02;
end

fig = figure('Units','normalized','Position',[0.1 0.1 0.8 0.6]);
plot(nyquist_rates, ENOBs, '-o', 'LineWidth',2, 'MarkerFaceColor',[1 .8 0], 'Color',[1 .6 0]);
grid on
ax = gca; ax.FontSize = 14; ax.LineWidth = 1;
xlabel('Nyquist Rate','FontSize',20);
ylabel('ENOB','FontSize',16);
title('ENOB vs Nyquist Rate (noise flooring)','FontSize',22);
xlim([min(nyquist_rates)*0.9, max(nyquist_rates)*1.05]);
ylim([min(ENOBs)-0.5, max(ENOBs)+0.5]);

for i=1:numel(nyquist_rates)
    text(nyquist_rates(i), ENOBs(i)+0.04, sprintf('%.2f',ENOBs(i)), 'HorizontalAlignment','center','FontSize',10);
end

if saveFigure
    set(gcf,'PaperPositionMode','auto');
    exportgraphics(fig, figureFilename, 'Resolution',300);
end

results.ENOBs = ENOBs;
results.SNRs_dB = SNRs_dB;
results.nyquist_rates = nyquist_rates;
results.N_out_samples = N_out_samples;
assignin('base','ENOB_sweep_results', results);
