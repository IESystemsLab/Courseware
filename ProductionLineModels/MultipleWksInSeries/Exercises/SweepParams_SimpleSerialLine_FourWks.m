%% Input Variables
arrivalRates = 0.2 : 0.1 : 0.9;  %Sweep over this
%arrivalRates = 0.3 : 0.2 : 0.9;

procTime_means = [1, 1, 1, 1];
procTime_SCVs = [10, 10, 10, 10];
queueCapacities = [Inf, Inf, Inf, Inf];
numberOfServers = [1, 1, 1, 1];

simEndTime = 50000;
nRepsPerPoint = 10;


%% Derived Values
InterarrivalTime_expMeans = 1 ./ arrivalRates;
procTime_vars = procTime_SCVs .* procTime_means.^2;
%Compute utilization at each workstation.  If the procTime_means or numberOfServers are not the same at each
%workstation, **then this value will be wrong**.
utilAtEachWks = arrivalRates .* procTime_means(1) / numberOfServers(1);


%% Simulate
WIP_reps = zeros(nRepsPerPoint, 1);
CT_reps = zeros(nRepsPerPoint, 1);
TH_reps = zeros(nRepsPerPoint, 1);
n = length(arrivalRates);
WIP_means = zeros(n, 1);
CT_means = zeros(n, 1);
TH_means = zeros(n, 1);

%Outer loop for sweep variable
for ii = 1 : n
    
    %Inner loop for replications
    for jj = 1 : nRepsPerPoint
        [WIP_reps(jj), CT_reps(jj), TH_reps(jj)] = SimWrapper_SimpleSerialLine_FourWks( ...
            InterarrivalTime_expMeans(ii), ...
            procTime_means, procTime_vars, ...
            queueCapacities, numberOfServers, simEndTime);
    end
    
    %Average over replications
    WIP_means(ii) = mean(WIP_reps);
    CT_means(ii) = mean(CT_reps);
    TH_means(ii) = mean(TH_reps);
end


%% Visualize
figure;
subplot(2,2,1)
plot(utilAtEachWks, CT_means);
box off
xlabel('Utilization at each Workstation');
ylabel('Average CT');

subplot(2,2,2)
plot(utilAtEachWks, WIP_means);
box off
xlabel('Utilization at each Workstation');
ylabel('Average WIP');

subplot(2,2,3)
plot(utilAtEachWks, TH_means);
box off
xlabel('Utilization at each Workstation');
ylabel('Average TH');
