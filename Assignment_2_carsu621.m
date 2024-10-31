%% Uppgift 2, Carl Sundquist (carsu621), TNK106

clear all;
close all;
clc;

%  Setting connection parameters.
host = 'localhost';
port = 5432;
database = 'courses';
username = 'tnk106';
password ='tnk1062020';

% Connecting to the database.
conn = postgresql(username, password, ...
                 'Server',host,'PortNumber',port, ...
                 'DatabaseName',database); 

% Hämtar data
query = "SELECT id AS station_id, ST_X(geom) AS x, ST_Y(geom) AS y FROM tnk106.handin_reference_stations WHERE id IN ('1', '2', '3')";
disp(query);
data = fetch(conn, query);
disp(data)

% Extraherar koordinater ur datan
R1 = [data.x(data.station_id == 1), data.y(data.station_id == 1)];
R2 = [data.x(data.station_id == 2), data.y(data.station_id == 2)];

% Vinklar vid R1 och R2 (grader)
angle_R1 = 25;
angle_R2 = 73;

% konvertera till radianer
angle_R1_rad = deg2rad(angle_R1);
angle_R2_rad = deg2rad(angle_R2);

% Räknar ut lutningar
slope_R1 = tan(angle_R1_rad);
slope_R2 = tan(angle_R2_rad);

% Ekvationer: y = mx + b
% Linjen genom R1: y - y1 = slope_R1 * (x - x1)
% Linjen genom R2: y - y2 = slope_R2 * (x - x2)
syms x y

eq1 = y - R1(2) == slope_R1 * (x - R1(1));
eq2 = y - R2(2) == slope_R2 * (x - R2(1));

% Lös för skärningspunkten
[sol_x, sol_y] = solve([eq1, eq2], [x, y]);

% Presentera resultat
disp('Positionsestimering med AOA:');
format long
disp([double(sol_x), double(sol_y)]);

figure;
hold on;
plot(R1(1), R1(2), 'bo', 'MarkerSize', 8, 'DisplayName', 'R1');
plot(R2(1), R2(2), 'go', 'MarkerSize', 8, 'DisplayName', 'R2');
plot(double(sol_x), double(sol_y), 'kx', 'MarkerSize', 10, 'DisplayName', 'Estimatering (AOA)');
legend;

fplot(@(x) slope_R1 * (x - R1(1)) + R1(2), [R1(1) - 500, R1(1) + 500], 'b--');
fplot(@(x) slope_R2 * (x - R2(1)) + R2(2), [R2(1) - 500, R2(1) + 500], 'g--');

xlabel('X koordinat (SWEREF99)');
ylabel('Y koordinat (SWEREF99)');
title('Positionsestimering med AOA Metoden');
grid on;
