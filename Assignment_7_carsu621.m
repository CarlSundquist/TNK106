%% Uppgift 7, Carl Sundquist (carsu621), TNK106, 2024-10-31


% Clear workspace
clear all;
close all;
clc;

% Step 1: Database Connection
% Setting up connection parameters
host = 'localhost';
port = 5432;
database = 'courses';
username = 'tnk106';
password = 'tnk1062020';

% Connecting to the database
conn = postgresql(username, password, ...
                 'Server', host, 'PortNumber', port, ...
                 'DatabaseName', database);

% Hämta data
% Nätverksdata
query_network = 'SELECT id, x1, y1, x2, y2, length, cost FROM handin_ex_8_network';
network_data = fetch(conn, query_network);

% GPS punkter
query_points = 'SELECT id, ST_X(geom) AS geom_X, ST_Y(geom) AS geom_Y, time, raw_speed FROM handin_ex_8_points';
points_data = fetch(conn, query_points);


close(conn);

% Definera parametrar för map-matching
mu_d = 10;
mu_alpha = 10;
a = 0.17;
n_d = 1.4;
n_alpha = 4;

% initiera array för att spara matchningar
matched_positions = [];

% implementera algoritmen
for i = 1:height(points_data)
    
    gps_point = points_data(i, :);
    gps_x = gps_point.geom_x;
    gps_y = gps_point.geom_y;
    
    best_match = NaN;
    best_probability = -Inf;
    best_closest_x = NaN;
    best_closest_y = NaN;
    
    % För varje vägsegment
    for j = 1:height(network_data)
       
        segment = network_data(j, :);
        x1 = segment.x1;
        y1 = segment.y1;
        x2 = segment.x2;
        y2 = segment.y2;
        
        % Räkna ut avståndet från vägsegmentet till gps-punkten
        % Använder punkt till linje formeln
        A = gps_x - x1;
        B = gps_y - y1;
        C = x2 - x1;
        D = y2 - y1;
        
        dot_product = A * C + B * D;
        length_squared = C^2 + D^2;
        param = -1;
        if length_squared ~= 0
            param = dot_product / length_squared;
        end
        
        if param < 0
            closest_x = x1;
            closest_y = y1;
        elseif param > 1
            closest_x = x2;
            closest_y = y2;
        else
            closest_x = x1 + param * C;
            closest_y = y1 + param * D;
        end
        
        % Avstånd från gps punkt till närmaste punkt på vägen
        distance = sqrt((gps_x - closest_x)^2 + (gps_y - closest_y)^2);
        
        % Räkna sannolikheten
        probability = exp(-((distance / mu_d)^n_d));
        
        % Uppdatera bästa matchningen
        if probability > best_probability
            best_match = segment;
            best_probability = probability;
            best_closest_x = closest_x;
            best_closest_y = closest_y;
        end
    end
    
    % Spara matchade positioner
    matched_positions = [matched_positions; table(gps_point.id, best_match.id, best_probability, best_closest_x, best_closest_y, ...
        'VariableNames', {'gps_id', 'matched_segment_id', 'probability', 'matched_x', 'matched_y'})];
end

% Exportera till QGIS
writetable(matched_positions, 'matched_positions.csv');
disp('Map-matching complete. Results with coordinates saved to matched_positions.csv');
