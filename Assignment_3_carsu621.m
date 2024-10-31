%% Uppgift 3, Carl Sundquist (carsu621), TNK106

clear all;
close all;
clc;

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
% Hämtar data
query = "SELECT id AS station_id, ST_X(geom) AS x, ST_Y(geom) AS y FROM tnk106.handin_reference_stations WHERE id IN ('1', '2', '3', '4')";
data = fetch(conn, query);

% Extraherar koordinater ur datan
R1 = [data.x(data.station_id == 1), data.y(data.station_id == 1)];
R2 = [data.x(data.station_id == 2), data.y(data.station_id == 2)];
R3 = [data.x(data.station_id == 3), data.y(data.station_id == 3)];
R4 = [data.x(data.station_id == 4), data.y(data.station_id == 4)];

% Avstånd
d1 = 880;
d2 = 280;
d3 = 1330;
d4 = 995;

% Distansbaserade cirkelekvationer
A = [
    2*(R2(1) - R1(1)), 2*(R2(2) - R1(2));
    2*(R3(1) - R1(1)), 2*(R3(2) - R1(2));
    2*(R4(1) - R1(1)), 2*(R4(2) - R1(2))
];

b = [
    d1^2 - d2^2 - R1(1)^2 + R2(1)^2 - R1(2)^2 + R2(2)^2;
    d1^2 - d3^2 - R1(1)^2 + R3(1)^2 - R1(2)^2 + R3(2)^2;
    d1^2 - d4^2 - R1(1)^2 + R4(1)^2 - R1(2)^2 + R4(2)^2
];

% Minstakvadratlösningen
estimated_pos = (A' * A) \ (A' * b);

% visualisera
disp('Estimering med LS:');
format long
disp(estimated_pos);


figure;
hold on;
plot(R1(1), R1(2), 'bo', 'MarkerSize', 8, 'DisplayName', 'R1');
plot(R2(1), R2(2), 'go', 'MarkerSize', 8, 'DisplayName', 'R2');
plot(R3(1), R3(2), 'ro', 'MarkerSize', 8, 'DisplayName', 'R3');
plot(R4(1), R4(2), 'mo', 'MarkerSize', 8, 'DisplayName', 'R4');
plot(estimated_pos(1), estimated_pos(2), 'kx', 'MarkerSize', 10, 'DisplayName', 'Estimering (LS)');
legend;
xlabel('X koordinat (SWEREF99)');
ylabel('Y koordinat (SWEREF99)');
title('Estimering av position med LS metoden');
grid on;
