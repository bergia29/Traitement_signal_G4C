clc; clear; close all; % Nettoyage de l'espace de travail et fermeture des figures

%% 1. Lecture du fichier audio
[y, Fs] = audioread('C:/Users/charn/OneDrive/Traitement_signal/fichiers_audios.mp3/FluteNote12.mp3'); % Chargement du fichier MP3

% Création du vecteur temps associé au signal
T = 1/Fs; % Période d'échantillonnage
t = (0:length(y)-1) * T; % Vecteur temps en secondes

%% 2. Génération d'un signal synthétique pour test
Fe = 48e3; % Fréquence d'échantillonnage
Te = 1/Fe;  % Période d'échantillonnage
D = 2; % Durée du signal (2 secondes)
t_syn = 0:Te:D; % Vecteur de temps
N = length(t_syn); % Nombre d'échantillons
f0_syn = 440; % Fréquence de la note (A4)
x = 0.2 * cos(2*pi*f0_syn*t_syn); % Signal sinusoïdal

% Ajouter un fondu en entrée et en sortie (pour simuler un signal musical)
K = round(N/4); % Nombre d'échantillons pour le fondu
x(1:K) = x(1:K) * 1e-8; % Fondu en entrée
x(end-K:end) = x(end-K:end) * 1e-8; % Fondu en sortie

%% 3. Détection des segments utiles
threshold = 0.01; % Seuil d'amplitude pour détecter les notes
energy = abs(y); % Calcul de l'enveloppe du signal (valeur absolue)

% Détection du premier et dernier échantillon dépassant le seuil
start_idx = find(energy > threshold, 1, 'first'); % Début du signal utile
end_idx = find(energy > threshold, 1, 'last'); % Fin du signal utile

% Extraction du segment détecté
y_useful = y(start_idx:end_idx); % Segment contenant la note
T_useful = t(start_idx:end_idx); % Vecteur temps associé

%% 4. Estimation de la fréquence fondamentale avec l'autocorrélation
f0 = autocorrelation(y_useful, Fs); % Détection de la fréquence principale

%% 5. Identification de la note correspondante
notes_freq = struct( ...
    'D4B', 277.18, 'E4', 329.63, 'G4b', 369.99, 'B4b', 466.16, ...
    'D5', 587.33, 'E5', 659.26, 'G5', 783.99, 'B5', 987.77, ...
    'C6', 1046.50, 'G4', 392.00, 'D4', 293.66, 'C4', 261.63, ...
    'A4', 440.00, 'A5', 880.00, 'B5b', 932.33, ...
   'E4b', 311.13, 'A4b', 415.30, 'B4', 493.88, ...
    'F5', 698.46 ...
);
frequencies = cell2mat(struct2cell(notes_freq));
[~, idx] = min(abs(frequencies - f0)); % Trouver la fréquence la plus proche
note_names = fieldnames(notes_freq); % Extraire les noms des notes
detected_note = note_names{idx}; % Note détectée

%% 6. Affichage des résultats
fprintf('Instant de début : %.4f secondes\n', t(start_idx));
fprintf('Instant de fin : %.4f secondes\n', t(end_idx));
fprintf('Fréquence fondamentale détectée : %.2f Hz\n', f0);
fprintf('Note détectée : %s\n', detected_note);

%% 7. Affichage des graphiques
figure;
subplot(2,1,1);
plot(t, y, 'b');
xlabel('Temps (s)'); ylabel('Amplitude');
title('Signal audio original'); grid on;

subplot(2,1,2);
plot(T_useful, y_useful, 'r');
xlabel('Temps (s)'); ylabel('Amplitude');
title('Segment détecté'); grid on;

%% --- Fonction d'autocorrélation ---
function f0 = autocorrelation(signal, Fs)
    signal = signal - mean(signal);  % Centrer le signal en retirant la moyenne
    R = xcorr(signal, 'coeff');  % Calcul de l'autocorrélation
    R = R(length(signal):end);  % Ne garder que la partie positive de l'autocorrélation
    [~, peak_idx] = max(R(2:end));  % Trouver le premier pic après t=0
    period = peak_idx + 1;  % La période est l'index du premier pic
    f0 = Fs / period;  % Calcul de la fréquence fondamentale
end
