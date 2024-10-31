%% Uppgift 5, Carl Sundquist (carsu621), TNK106

clear all;
close all;
clc;

% Setting up the connection parameters
host = 'localhost';
port = 5432;
database = 'courses';
username = 'tnk106';
password = 'tnk1062020';

% Connecting to the database
conn = postgresql(username, password, ...
                 'Server',host,'PortNumber',port, ...
                 'DatabaseName',database);

% Hämta data
query = "SELECT fp_id, pos_id, mac, rssi FROM tnk106.handin_ex_5 WHERE name = 'LiU' AND (fp_id = '1' OR fp_id IN ('2', '3', '4', '5'))";
data = fetch(conn, query);

close(conn);

% Separera mätning och fingerprint
measurement = data(strcmp(data.fp_id, '1'), :);
fingerprints = data(ismember(data.fp_id, {'2', '3', '4', '5'}), :);


fingerprint_ids = unique(fingerprints.fp_id);
distances = zeros(length(fingerprint_ids), 1);

for i = 1:length(fingerprint_ids)
    fp_id = fingerprint_ids(i);
    
    % Hämta signalstyrka från fingerprint och mätning
    fingerprint_rssi = fingerprints.rssi(fingerprints.fp_id == fp_id);
    measurement_rssi = measurement.rssi;
    
    % Hitta gemensamma mac-adresser (Accespunkter)
    [common_mac, idx_fp, idx_meas] = intersect(fingerprints.mac(fingerprints.fp_id == fp_id), measurement.mac);
    
    % Räkna ut euklidiskt avstånd
    distances(i) = sqrt(sum((fingerprint_rssi(idx_fp) - measurement_rssi(idx_meas)).^2));
end

% Hitta det fingerprint med minsta avstånd
[~, min_index] = min(distances);
closest_fingerprint = fingerprint_ids(min_index);

% Visa resultat
disp(['Det fingerprint som mest liknar mätningen är: fp_id = ', num2str(closest_fingerprint)]);
