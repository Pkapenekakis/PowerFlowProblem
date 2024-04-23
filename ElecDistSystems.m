function [V, delta, P, Q, losses, injected_P_ref] = PowerFlow() %check whether the function needs to return something

baseP = 100; % Base Power 100MVA
Voltagelimits = 0.06; % given as 6%
Vmax = (1 + Voltagelimits) * baseP; % Άνω όριο Τάσης
Vmin = (1 - Voltagelimits) * baseP; % Κάτω όριο Τάσης
accuracy = 0.001; % Ακρίβεια 

%TODO Check Vm (why 0) check Va (For non generator, since in generator we
%have the Vg (same as Va) WHY 1.01 or w/e value TODO
%Bus Data of the System - essentially the bus connections TODO check if I
%understand correctly

%busNum busType PL QL Bs Vm Va Vmax Vmin
busData = [
    1   1   0     0     0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    2   2   21.7  12.7  0   0   1.045 * baseP 0.0  (1.045 + Voltagelimits) * baseP (1.045 - Voltagelimits) * baseP;
    3   2   94.2  19    0   0   1.01 * baseP  0.0  (1.01 + Voltagelimits) * baseP  (1.01 - Voltagelimits) * baseP;
    4   1   47.8  -3.9  0   0   1.01 * baseP  0.0  (1.01 + Voltagelimits) * baseP  (1.01 - Voltagelimits) * baseP;
    5   1   7.6   1.6   0   0   1.01 * baseP  0.0  (1.01 + Voltagelimits) * baseP  (1.01 - Voltagelimits) * baseP;
    6   2   11.2  7.5   0   0   1.07 * baseP  0.0  (1.07 + Voltagelimits) * baseP  (1.07 - Voltagelimits) * baseP;
    7   1   0     0     0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    8   2   0     0     0   0   1.09 * baseP  0.0  (1.09 + Voltagelimits) * baseP  (1.09 - Voltagelimits) * baseP;
    9   1   29.5  16.6  19  0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    10  1   9     5.8   0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    11  1   3.5   1.8   0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    12  1   6.1   1.6   0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    13  1   13.5  5.8   0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
    14  1   14.9  5     0   0   1.06 * baseP  0.0  (1.06 + Voltagelimits) * baseP  (1.06 - Voltagelimits) * baseP;
];

%Generator Data of the System
%Bus Pg Qg Pgmax Pgmin Qgmax Qgmin Vg workState
genData = [
    1 232.4 0 -332.4 0 0 10 0 1.06 1
    2 40 0 -140 0 0 50 -40 1.045 1
    3 0 0 -100 0 0 40 0 1.01 1
    6 0 0 -100 0 0 24 -6 1.07 1
    8 0 0 -100 0 0 24 -6 1.09 1
];

%Line Data of the System
%TODO Check D Dmin Dmax and workState values
%Transfer line Data of the System
%From To R X B transfLim D Dmin Dmax workState
lineData = [
    1 2 0.01938 0.05917 0.0528 0.5 0 0 1
    1 5 0.05403 0.22304 0.0492 0.5 0 0 1
    2 3 0.04699 0.19797 0.0438 0.5 0 0 1
    2 4 0.05811 0.17632 0.034 0.5 0 0 1
    2 5 0.05695 0.17388 0.0346 0.5 0 0 1
    3 4 0.06701 0.17103 0.0128 0.5 0 0 1
    4 5 0.01335 0.04211 0 0.5 0 0 1
    4 7 0 0.20912 0 0.5 0 0 1
    4 9 0 0.55618 0 0.5 0 0 1
    5 6 0 0.25202 0 0.5 0 0 1
    6 11 0.09498 0.1989 0 0.5 0 0 1
    6 12 0.12291 0.25581 0 0.5 0 0 1
    6 13 0.06615 0.13027 0 0.5 0 0 1
    7 8 0 0.17615 0 0.5 0 0 1
    7 9 0 0.11001 0 0.5 0 0 1
    9 10 0.03181 0.0845 0 0.5 0 0 1
    9 14 0.12711 0.27038 0 0.5 0 0 1
    10 11 0.08205 0.19207 0 0.5 0 0 1
    12 13 0.22092 0.19988 0 0.5 0 0 1
    13 14 0.17093 0.34802 0 0.5 0 0 1
];

%Working cost of the generators
%n c2 c1 c0
costData = [
    3 0.1 20 0
    3 0.25 20 0
    3 0.01 40 0
    3 0.01 40 0
    3 0.01 40 0
];


%Initialise data based on the size of the arrays
%That ensures only the tables above need to be changed for a different
%system

busNum = size(busData, 1);
linesNum = size(lineData, 1);
genNum = size(genData, 1);
costCoefNum = size(costData, 2) - 1;
V = ones(busNum, 1); %Initial Voltage
delta = zeros(busNum, 1); %Initial Delta

% Formatting the transfer line data
lineDataMatrix = zeros(num_bus, num_bus); % Initialize the linedata matrix with zeros
impedanceMatrix = zeros(num_bus, num_bus); % Initialize the impedance matrix with zeros
suscMatrix = zeros(num_bus, num_bus); % Initialize the susceptance matrix with zeros

for k = 1:num_lines
    i = lineData(k, 1); % Starting bus of the line
    j = lineData(k, 2); % Ending bus of the line
    res = lineData(k, 3); % Resistance of the line
    reactance = lineData(k, 4); % Reactance of the line
    susc = lineData(k, 5); % Susceptance of the line
    
    % Store the line number for each pair of buses
    lineDataMatrix(i, j) = k;
    lineDataMatrix(j, i) = k;
    
    % Store the impedance in the corresponding location in the Z matrix
    impedanceMatrix(i, j) = res + 1i * reactance; %1i represents the imaginary unit i in Matlab
    impedanceMatrix(j, i) = res + 1i * reactance; %1i represents the imaginary unit i in Matlab
    

    % Store the susceptance (ευαισθησία) in the corresponding location in the B matrix
    suscMatrix(i, j) = 1i * susc; %1i represents the imaginary unit i in Matlab
    suscMatrix(j, i) = 1i * susc; %1i represents the imaginary unit i in Matlab
end

%Initializing transfer Lines
Pij = zeros(num_bus, num_bus);
Qij = zeros(num_bus, num_bus);
for i = 1:num_bus
    for j = 1:num_bus
        if linedata(i, j) ~= 0 %Not equal to 0 means there is a line between the two busses
            res = real(lineDataMatrix(i, j));
            reactance = imag(lineDataMatrix(i, j));
            susc = imag(suscMatrix(i, j));
            Pij(i, j) = (V(i)^2 * res - V(i) * V(j) * (res * cos(delta(i) - delta(j)) + reactance * sin(delta(i) - delta(j)))) / (res^2 + reactance^2);
            Qij(i, j) = (-V(i)^2 * (susc / 2) - V(i) * V(j) * (res * sin(delta(i) - delta(j)) - reactance * cos(delta(i) - delta(j)))) / (res^2 + reactance^2);
        end
    end
end


%Initialize generators
P = zeros(num_bus, 1);
Q = zeros(num_bus, 1);
Pg = zeros(num_bus, 1);
Qg = zeros(num_bus, 1);
Qmin = zeros(num_bus, 1);
Qmax = zeros(num_bus, 1);
Pgmax = zeros(num_bus, 1);
Pgmin = zeros(num_bus, 1);
for i = 1:num_bus
    if busdata(i, 2) == 2 %If the bus is a generator
        %genData contains the data of each generator
        %busData(i,1) gets the data of the generator connected to bus i
        %The last index 2,3 etc gets the appropriate value from the genData
        %array
        Pg(i) = genData(busData(i, 1), 2) / baseP; 
        Qg(i) = genData(busData(i, 1), 3) / baseP;
        Pgmax(i) = genData(busData(i, 1), 4) / baseP;
        Pgmin(i) = genData(busData(i, 1), 5) / baseP;
        Qmax(i) = genData(busData(i, 1), 6) / baseP;
        Qmin(i) = genData(busData(i, 1), 7) / baseP;
    end
end


% Αρχικοποίηση κόστους λειτουργίας
workCost = zeros(busNum, costCoefNum);
for i = 1:num_bus
    if busdata(i, 2) == 2 %If the bus is a generator there is an associated cost
        workCost(i, :) = costData(genData(busData(i, 1), 1), 2:end);
    end
end











