%% Uppgift 8, Carl Sundquist (carsu621), TNK106, 2024-10-31

clear all;
close all;
clc;


%Creating a database connection.
%  Setting connection parameters.
host = 'localhost';
port = 5432;
database = 'courses';
username = 'tnk106';
password ='tnk1062020';

% Connecting to the database.
%  Note: Make sure to close the connection when you are not needing it
%        any more so you are not locking up a connection.
conn = postgresql(username, password, ...
                 'Server',host,'PortNumber',port, ...
                 'DatabaseName',database);

%Fetching data and performing calculations.
%try
    % get training data aggregated per grid square

%main cell data
    sql = ['SELECT g.id, cell_id, '...
       'avg(c.rss::double precision) AS avg_rss, '...
       'stddev(c.rss::double precision) AS rss_stdev, '...
       'count(*) AS count, '...
       'g.geom '...
       'FROM tnk106.handin_ex_6_training c '...
       'JOIN tnk106.handin_ex_6_grid_50 g ON st_within(c.geom, g.geom) '...
       'GROUP BY g.id, g.geom, cell_id'];


    disp(sql)
    data = conn.fetch(sql);

    [testx,testy]=Gridxy(33);

%neighbour cell data
    sql2 = ['SELECT g.id, n_cell_id, '...
        'avg(c.n_rss::double precision) AS avg_rss, '...
        'stddev(c.n_rss::double precision) AS rss_stdev, '...
        'count(*) AS count, '...
        'g.geom '...
        'FROM tnk106.handin_ex_6_training c '...
        'JOIN tnk106.handin_ex_6_grid_50 g ON st_within(c.geom, g.geom) '...
        'GROUP BY g.id, g.geom, n_cell_id'];


    disp(sql2)
    data2 = conn.fetch(sql2);

    sql3 = ['SELECT * from tnk106.handin_ex_6_test'];
    disp(sql3)
    data3 = conn.fetch(sql3);
    

    allowed_signalSTRs=(50);
    penaltyFactors=(0.3);

    for penaltyTest=1:length(penaltyFactors)
        penaltyFactor=penaltyFactors(penaltyTest);
        for Filtertest=1:length(allowed_signalSTRs)
        allowed_signalSTR=allowed_signalSTRs(Filtertest);
    % calculate grid square probability
    grid_ids = unique(data.id);
    meas_ids = unique(data3.id_observation);

    %Preallocating
    distances=zeros(length(meas_ids),length(grid_ids));
    penalties=zeros(length(meas_ids),length(grid_ids));
    Guessed_grid=zeros(length(meas_ids),1);
    %Correct_grid=zeros(length(meas_ids),1);
    for i = 1:length(meas_ids)
        meas = data3(data3.id_observation == meas_ids(i),:);
        %Retreive measured rssi and cellid
        mRssi=unique(meas.rss)+140;
        mCell=unique(meas.cell_id);
        nRssi=meas.n_rss+140;
        nCell=meas.n_cell_id;


        
        for j = 1:length(grid_ids)
          
            % main and neighbouring cells needs to be compared separately
            fp_main = data(data.id == grid_ids(j),:);
            fp_neighbour = data2(data2.id == grid_ids(j),:);

            %Retrive fingerprint rssi and cellid
            fpRssi=fp_main.avg_rss+140;
            fpCell=fp_main.cell_id;
            fp_nRssi=fp_neighbour.avg_rss+140;
            fp_nCell=fp_neighbour.n_cell_id;

            %Find matching cellids to compare rssi between measured and
            %fingerprints for Main and neighbour cells
            [main_match, meas_id,fp_id]=intersect(mCell,fpCell);
            [neighbor_match,meas_nid,fp_nid]=intersect(nCell,fp_nCell);
            [Notmatching_m,No_meas_i]=setdiff(nCell,fp_nCell);
            [Notmatching_fp,No_fp_i]=setdiff(fp_nCell,nCell);

            if ~isempty(main_match)
                m_distance=sqrt((mRssi(meas_id)-fpRssi(fp_id))^2);
            else
                m_distance=NaN;
            end

            if~isempty(neighbor_match)
                n_distance=sqrt(sum((nRssi(meas_nid))-fp_nRssi(fp_nid)).^2);
                
                
                
                if ~isempty(Notmatching_m) || ~isempty(Notmatching_fp)
                    filtered_fp_n_rssi=fp_nRssi(No_fp_i);
                    penalty=sqrt(sum(nRssi(No_meas_i).^2)+sum(filtered_fp_n_rssi(filtered_fp_n_rssi>allowed_signalSTR).^2))*penaltyFactor;
                    n_distance=n_distance+penalty;
                end
            else
                n_distance=NaN;
            end
            
            %penalties(i,j)=penalty;
            distances(i,j)=m_distance+n_distance;
            % calculate a a distance between measurement (meas) 
            % and fingerprint (fp_main/fp_neighbour) here
                     
        end
        [testMin,gridIndex]=min(distances(i,:));
        Guessed_grid(i)=grid_ids(gridIndex);
        %Correct_grid(i)=unique(data5(meas_ids(i)==data5.id_observation,:).grid_id);

            % Spara bästa matchningens gridposition (mittpunkten av grid-rutan)
    if ~isnan(Guessed_grid(i))
        result = fetch(conn, sprintf('SELECT ST_X(ST_Centroid(geom)), ST_Y(ST_Centroid(geom)) FROM handin_ex_6_grid_50 WHERE id = %d', Guessed_grid(i)));
        
        % Kontrollera att resultatet inte är tomt innan tilldelning
        if ~isempty(result)
            estimated_positions(i, :) = [result.st_x, result.st_y];
        else
            warning('Ingen matchande grid hittades för id %d', Guessed_grid(i));
        end
    end

    end
    

    end
    
    end
    



% Fetch actual positions for each observation
sql_actual_positions = 'SELECT id_observation, ST_X(geom) AS actual_x, ST_Y(geom) AS actual_y FROM tnk106.handin_ex_6_test';
actual_positions_data = conn.fetch(sql_actual_positions);

% Initialize an array to store distances between estimated and actual positions
distances_to_actual = zeros(length(meas_ids), 1);

% Loop through each observation to calculate distance
for i = 1:length(meas_ids)
    % Retrieve actual position for current observation
    actual_position = actual_positions_data(actual_positions_data.id_observation == meas_ids(i), :);

    % Calculate Euclidean distance between estimated and actual positions
    if ~isempty(actual_position)
        estimated_x = estimated_positions(i, 1);
        estimated_y = estimated_positions(i, 2);
        actual_x = actual_position.actual_x;
        actual_y = actual_position.actual_y;

        % Compute the distance
        distances_to_actual(i) = sqrt((estimated_x - actual_x(1))^2 + (estimated_y - actual_y(1))^2);
    else
        warning('No actual position found for observation %d', meas_ids(i));
        distances_to_actual(i) = NaN;
    end
end

% Remove any NaN values (if any actual positions were missing)
distances_to_actual = distances_to_actual(~isnan(distances_to_actual));

% Plot the accuracy using the ECDF of distances
figure;
ecdf(distances_to_actual);
title('ECDF');
xlabel('Avståndsfel (meter)');
ylabel('Kumulativ sannolikhet');
grid on;
    
conn.close;

% Ange SRID (exempelvis 3006 för SWEREF99 TM)
SRID = 3006;

% Initialisera en räknare för varje grid_id
grid_ids = unique(Guessed_grid);
grid_counts = histc(Guessed_grid, grid_ids);

% Initialisera SQL-strängen med den första gridcellen
sql_query = "SELECT 'Estimering' AS namn, " + ...
            num2str(grid_counts(1)) + " AS count, " + ...
            num2str(grid_ids(1)) + " AS grid_id, " + ...
            "ST_SetSRID(ST_MakePoint(" + ...
            num2str(estimated_positions(1,1), '%.4f') + ", " + ...
            num2str(estimated_positions(1,2), '%.4f') + "), " + ...
            num2str(SRID) + ") AS geom";

% Bygg SQL-satsen med UNION ALL för varje gridcell
for i = 2:length(grid_ids)
    % Hitta de index i estimated_positions som motsvarar den aktuella gridcellen
    grid_idx = Guessed_grid == grid_ids(i);
    % Extrahera den första positionen i estimated_positions för denna gridcell
    x = estimated_positions(find(grid_idx, 1), 1);
    y = estimated_positions(find(grid_idx, 1), 2);
    
    % Lägg till nästa SELECT-sats med grid_id och count
    sql_query = sql_query + newline + ...
                "UNION ALL SELECT 'Estimering', " + ...
                num2str(grid_counts(i)) + " AS count, " + ...
                num2str(grid_ids(i)) + " AS grid_id, " + ...
                "ST_SetSRID(ST_MakePoint(" + num2str(x, '%.4f') + ", " + ...
                num2str(y, '%.4f') + "), " + num2str(SRID) + ") AS geom";
end

% Avsluta SQL-satsen med ett semikolon
sql_query = sql_query + ";";

% Visa den färdiga SQL-frågan
disp(sql_query);


%% KALMANFILTER

% Initiera filter-parametrar
F = eye(2); 
H = eye(2);
Q = 0.01 * eye(2); 
R = 0.1 * eye(2);
P = eye(2); 
x = estimated_positions(1, :)'; %Första positionen

% Applicera kalmanfilter till estimeringarna
filtered_positions = zeros(size(estimated_positions));
for k = 1:size(estimated_positions, 1)
    % Uppdatera mätning
    z = estimated_positions(k, :)';
    
    % Prediktering
    x = F * x;
    P = F * P * F' + Q;
    
    % Kalman-gain
    K = P * H' / (H * P * H' + R);
    
    % Uppdatera
    x = x + K * (z - H * x);
    P = (eye(2) - K * H) * P;
    
    % Spara filtrerade positioner
    filtered_positions(k, :) = x';
end



% Preallokera
unfiltered_errors = zeros(length(meas_ids), 1);
filtered_errors = zeros(length(meas_ids), 1);

% Räkna avståndet för varje position
for i = 1:length(meas_ids)
    % Hämta faktisk position
    actual_position = actual_positions_data(actual_positions_data.id_observation == meas_ids(i), :);

    % Räkna euklidiskt avstånd mellan estimering, filtrerad och faktisk
    if ~isempty(actual_position)
        estimated_x = estimated_positions(i, 1);
        estimated_y = estimated_positions(i, 2);
        filtered_x = filtered_positions(i, 1);
        filtered_y = filtered_positions(i, 2);
        actual_x = actual_position.actual_x;
        actual_y = actual_position.actual_y;

        unfiltered_errors(i) = sqrt((estimated_x - actual_x(1))^2 + (estimated_y - actual_y(1))^2);
        filtered_errors(i) = sqrt((filtered_x - actual_x(1))^2 + (filtered_y - actual_y(1))^2);
    else
        warning('Ingen faktisk position hittad för observation %d', meas_ids(i));
        unfiltered_errors(i) = NaN;
        filtered_errors(i) = NaN;
    end
end

% Ta bort NaN värden
unfiltered_errors = unfiltered_errors(~isnan(unfiltered_errors));
filtered_errors = filtered_errors(~isnan(filtered_errors));

% Plotta ECDF för filtrerade och ofiltrerade
figure;
hold on;
ecdf(unfiltered_errors);
ecdf(filtered_errors);
legend('Ofiltrerad estimering', 'Filtrerad estimering');
title('ECDF');
xlabel('Fel (meters)');
ylabel('Kumulativ fördelning');
grid on;




function [x,y]=Gridxy(gridId)

x=floor(gridId/16)+1;
y=mod(gridId,16);

end
