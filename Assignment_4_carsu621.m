%% Uppgift 4, Carl Sundquist (carsu621), TNK106

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


% Avståndsskillnader
dR1_R2 = -490;
dR1_R3 = 460;

% Symboliska variabler för positionen (x, y) av den mobila terminalen
syms x y

% Definiera ekvationerna baserat på avståndsskillnaderna
eq1 = sqrt((x - R1(1))^2 + (y - R1(2))^2) - sqrt((x - R2(1))^2 + (y - R2(2))^2) == dR1_R2;
eq2 = sqrt((x - R1(1))^2 + (y - R1(2))^2) - sqrt((x - R3(1))^2 + (y - R3(2))^2) == dR1_R3;

% Lös systemet av ekvationer
[sol_x, sol_y] = solve([eq1, eq2], [x, y]);

% Visa resultaten
disp('Estimaterad position:')
%format long
disp([double(sol_x), double(sol_y)])

% Visualisera referensstationerna och den uppskattade positionen med hyperbeler
figure;
hold on;
plot(R1(1), R1(2), 'bo', 'MarkerSize', 8, 'DisplayName', 'R1');
plot(R2(1), R2(2), 'go', 'MarkerSize', 8, 'DisplayName', 'R2');
plot(R3(1), R3(2), 'ro', 'MarkerSize', 8, 'DisplayName', 'R3');
plot(double(sol_x), double(sol_y), 'kx', 'MarkerSize', 10, 'DisplayName', 'Estimaterad position');

% Rita hyperbelen för avståndsskillnaden mellan R1 och R2
syms x y
dist_diff_R1_R2 = sqrt((x - R1(1))^2 + (y - R1(2))^2) - sqrt((x - R2(1))^2 + (y - R2(2))^2) - dR1_R2;
fimplicit(dist_diff_R1_R2, [R1(1)-1000, R1(1)+1000, R1(2)-1000, R1(2)+1000], 'g--', 'DisplayName', 'Hyperbel R1-R2');

% Rita hyperbelen för avståndsskillnaden mellan R1 och R3
dist_diff_R1_R3 = sqrt((x - R1(1))^2 + (y - R1(2))^2) - sqrt((x - R3(1))^2 + (y - R3(2))^2) - dR1_R3;
fimplicit(dist_diff_R1_R3, [R1(1)-1000, R1(1)+1000, R1(2)-1000, R1(2)+1000], 'r--', 'DisplayName', 'Hyperbel R1-R3');

% Lägg till linjer från referensstationerna till den uppskattade positionen
plot([R1(1) double(sol_x)], [R1(2) double(sol_y)], 'b:', 'DisplayName', 'Avstånd till R1');
plot([R2(1) double(sol_x)], [R2(2) double(sol_y)], 'g:', 'DisplayName', 'Avstånd till R2');
plot([R3(1) double(sol_x)], [R3(2) double(sol_y)], 'r:', 'DisplayName', 'Avstånd till R3');

% Anpassa grafen
legend;
xlabel('X Koordinat (SWEREF99)');
ylabel('Y Koordinat (SWEREF99)');
title('Estimering m.h.a TDOA ');
axis equal;
grid on;
hold off;