%% Uppgift 1, Carl Sundquist (carsu621), TNK106, 2024-10-31

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
R3 = [data.x(data.station_id == 3), data.y(data.station_id == 3)];


% Distanserna från referensstationerna
d1 = 280;   % distance to R1
d2 = 1340;  % distance to R2
d3 = 950;   % distance to R3

% Ställer upp ekvationerna
% (x - x1)^2 + (y - y1)^2 = d1^2
% (x - x2)^2 + (y - y2)^2 = d2^2
% (x - x3)^2 + (y - y3)^2 = d3^2

syms x y

eq1 = (x - R1(1))^2 + (y - R1(2))^2 == d1^2;
eq2 = (x - R2(1))^2 + (y - R2(2))^2 == d2^2;
eq3 = (x - R3(1))^2 + (y - R3(2))^2 == d3^2;

eq4 = eq1 - eq2;
eq5 = eq1 - eq3;


% Löser ekvationssystemet
[sol_x, sol_y] = solve([eq4, eq5], [x, y]);

% Presenterar resultaten
disp('Möjlig position för terminalen:');
format long
disp([double(sol_x), double(sol_y)]);

figure;
hold on;
plot(R1(1), R1(2), 'bo', 'MarkerSize', 8, 'DisplayName', 'R1');
plot(R2(1), R2(2), 'go', 'MarkerSize', 8, 'DisplayName', 'R2');
plot(R3(1), R3(2), 'ro', 'MarkerSize', 8, 'DisplayName', 'R3');
plot(double(sol_x), double(sol_y), 'kx', 'MarkerSize', 10, 'DisplayName', 'Estimated Position');
legend;
xlabel('X koordinat (SWEREF99)');
ylabel('Y koordinat (SWEREF99)');
title('Positionsestimering med TOA Metoden');
grid on;