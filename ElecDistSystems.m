function [V, delta, P, Q, losses, injected_P_ref] = PowerFlow() %check whether the function needs to return something

baseP = 100; % Base Power 100MVA
Voltagelimits = 0.06 % given as 6%
Vmax = (1 + Voltagelimits) * BaseP; % Άνω όριο Τάσης
Vmin = (1 - Voltagelimits) * BaseP; % Κάτω όριο Τάσης
accuracy = 0.001; % Ακρίβεια 

%TODO Check Vm (why 0) check Va (For non generator, since in generator we
%have the Vg (same as Va) WHY 1.01 or w/e value TODO
%Bus Data of the System
%busNum busType PL QL Bs Vm Va Vmax Vmin
busdata = [
    1   1   0     0     0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    2   2   21.7  12.7  0   0   1.045 * baseMVA 0.0  (1.045 + V_percentage) * baseMVA (1.045 - V_percentage) * baseMVA;
    3   2   94.2  19    0   0   1.01 * baseMVA  0.0  (1.01 + V_percentage) * baseMVA  (1.01 - V_percentage) * baseMVA;
    4   1   47.8  -3.9  0   0   1.01 * baseMVA  0.0  (1.01 + V_percentage) * baseMVA  (1.01 - V_percentage) * baseMVA;
    5   1   7.6   1.6   0   0   1.01 * baseMVA  0.0  (1.01 + V_percentage) * baseMVA  (1.01 - V_percentage) * baseMVA;
    6   2   11.2  7.5   0   0   1.07 * baseMVA  0.0  (1.07 + V_percentage) * baseMVA  (1.07 - V_percentage) * baseMVA;
    7   1   0     0     0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    8   2   0     0     0   0   1.09 * baseMVA  0.0  (1.09 + V_percentage) * baseMVA  (1.09 - V_percentage) * baseMVA;
    9   1   29.5  16.6  19  0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    10  1   9     5.8   0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    11  1   3.5   1.8   0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    12  1   6.1   1.6   0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    13  1   13.5  5.8   0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
    14  1   14.9  5     0   0   1.06 * baseMVA  0.0  (1.06 + V_percentage) * baseMVA  (1.06 - V_percentage) * baseMVA;
];

%Generator Data of the System
%Bus Pg Qg Pgmax Pgmin Qgmax Qgmin Vg workState
generator_data = [
    1 232.4 0 -332.4 0 0 10 0 1.06 1
    2 40 0 -140 0 0 50 -40 1.045 1
    3 0 0 -100 0 0 40 0 1.01 1
    6 0 0 -100 0 0 24 -6 1.07 1
    8 0 0 -100 0 0 24 -6 1.09 1
];


%TODO Check D Dmin Dmax and workState values
%Transfer line Data of the System
%From To R X B transfLim D Dmin Dmax workState
line_data = [
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
cost_data = [
    3 0.1 20 0
    3 0.25 20 0
    3 0.01 40 0
    3 0.01 40 0
    3 0.01 40 0
];


%Initialise data based on the size of the arrays
%That ensures only the tables above need to be changed for a different
%system

busNum = size(busdata, 1);
linesNum = size(line_data, 1);
genNum = size(generator_data, 1);
costCoefNum = size(cost_data, 2) - 1;
V = ones(num_bus, 1); %Initial Voltage
delta = zeros(num_bus, 1); %Initial Delta

% Formatting the transfer line data
linedata = zeros(num_bus, num_bus); % Initialize the linedata matrix with zeros
Z = zeros(num_bus, num_bus); % Initialize the impedance matrix with zeros
B = zeros(num_bus, num_bus); % Initialize the susceptance matrix with zeros

for k = 1:num_lines
    i = line_data(k, 1); % Starting bus of the line
    j = line_data(k, 2); % Ending bus of the line
    r = line_data(k, 3); % Resistance of the line
    x = line_data(k, 4); % Reactance of the line
    b = line_data(k, 5); % Susceptance of the line
    
    % Store the line number for each pair of buses
    linedata(i, j) = k;
    linedata(j, i) = k;
    
    % Store the impedance in the corresponding location in the Z matrix
    Z(i, j) = r + 1i * x; %1i represents the imaginary unit i in Matlab
    Z(j, i) = r + 1i * x; %1i represents the imaginary unit i in Matlab
    
    % Store the susceptance in the corresponding location in the B matrix
    B(i, j) = 1i * b; %1i represents the imaginary unit i in Matlab
    B(j, i) = 1i * b; %1i represents the imaginary unit i in Matlab
end
