clc; clear; close all; % Nettoyage

%% 1. Lecture du fichier audio
[y, Fs] = audioread('C:/Users/charn/OneDrive/Traitement_signal/fichiers_audios.mp3/FluteNote12.mp3'); 
T = 1/Fs;
t = (0:length(y)-1) * T;

%% 2. Détection des notes
threshold = 0.01; 
energy = abs(y); 
start_idx = find(energy > threshold, 1, 'first'); 
end_idx = find(energy > threshold, 1, 'last'); 

% Extraction du segment utile
y_note = y(start_idx:end_idx); 
t_note = t(start_idx:end_idx);
D = t(end_idx) - t(start_idx); % Durée de la note

%% 3. Puissance moyenne en dBm
PdBm = 10 * log10(mean(y_note.^2) / (1e-3));

%% 4. Estimation de la fréquence fondamentale
f0a = autocorrelation(y_note, Fs); % Autocorrélation
f0f = spectral_analysis(y_note, Fs); % Transformée de Fourier

%% 5. Recherche de la note correspondante
notes_freq = struct( ...
    'D4b', 277.18, 'E4', 329.63, 'G4b', 369.99, 'B4b', 466.16, ...
    'D5', 587.33, 'E5', 659.26, 'G5', 783.99, 'B5', 987.77, ...
    'C6', 1046.50, 'G4', 392.00, 'D4', 293.66, 'C4', 261.63, ...
    'A4', 440.00, 'A5', 880.00, 'B5b', 932.33, ...
   'E4b', 311.13, 'A4b', 415.30, 'B4', 493.88, ...
    'F5', 698.46 ...
);
frequencies = cell2mat(struct2cell(notes_freq));
[~, idx1] = min(abs(frequencies - f0a));
[~, idx2] = min(abs(frequencies - f0f));

note_names = fieldnames(notes_freq);
detected_note_a = note_names{idx1}; % Par autocorrélation
detected_note_f = note_names{idx2}; % Par spectre

%% 6. Analyse des harmoniques
[fh, nh] = harmonic_analysis(y_note, Fs);

%% 7. Affichage des résultats
fprintf('Début : %.4f s | Fin : %.4f s | Durée : %.4f s\n', t(start_idx), t(end_idx), D);
fprintf('Puissance moyenne : %.2f dBm\n', PdBm);
fprintf('f0 (Autocorrélation) : %.2f Hz -> Note : %s\n', f0a, detected_note_a);
fprintf('f0 (Spectre) : %.2f Hz -> Note : %s\n', f0f, detected_note_f);
fprintf('Fréquence haute : %.2f Hz | Nombre d’harmoniques : %d\n', fh, nh);

%% 8. Fonctions annexes
function f0 = autocorrelation(signal, Fs)
    signal = signal - mean(signal);
    R = xcorr(signal, 'coeff');
    R = R(length(signal):end);
    [~, peak_idx] = max(R(2:end));
    period = peak_idx + 1;
    f0 = Fs / period;
end

function f0 = spectral_analysis(signal, Fs)
    Y = abs(fft(signal));
    freqs = (0:length(Y)-1) * Fs / length(Y);
    [~, peak_idx] = max(Y(2:end)); % Ignorer DC
    f0 = freqs(peak_idx + 1);
end

function [fh, nh] = harmonic_analysis(signal, Fs)
    Y = abs(fft(signal));
    power_spectrum = Y.^2;
    cumulative_power = cumsum(power_spectrum) / sum(power_spectrum);
    fh_idx = find(cumulative_power >= 0.9999, 1, 'first');
    fh = (fh_idx - 1) * Fs / length(Y);
    nh = sum(Y > max(Y) * 0.1); % Comptage des harmoniques
end
