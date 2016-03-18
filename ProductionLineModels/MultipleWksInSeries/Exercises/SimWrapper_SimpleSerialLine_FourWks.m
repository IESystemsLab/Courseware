function [ WIP_average, CT_average, TH_average ] = SimWrapper_SimpleSerialLine_FourWks( ...
    InterarrivalTime_expMean, ...
    ProcessingTime_logNormMeans, ProcessingTime_logNormVars, ...
	AllWksQueueCapacities, AllWksNumberServers, simEndTime )
% This SimWrapper handles the dirty work of converting MATLAB-function inputs to simulation model configuration.


%% Limited Validation of Inputs
nWks = 4;
if length(ProcessingTime_logNormMeans) ~= nWks ...
    || length(ProcessingTime_logNormVars) ~= nWks ...
    || length(AllWksQueueCapacities) ~= nWks ...
    || length(AllWksNumberServers) ~= nWks
    error('Certain inputs must be four-element vectors, because the underlying simulation model is hard-coded with four serial workstations.');
end


%% Open Discrete-Event Simulation Model
sysName = 'SimpleSerialLine_FourWksWithPreempFailures';
open_system(sysName);


%% Set Inter-Arrival Time Distribution
arrivalGenPath = [sysName '/Arrival Generator'];
set_param(arrivalGenPath , 'Distribution', 'Exponential');
set_param(arrivalGenPath , 'mean', num2str(InterarrivalTime_expMean));


%% Set Processing Time Distributions
workstationName = 'GGkWorkstation_RandomCalendarTimeUntilPreempFailure';
for ii = 1 : nWks
    rngenPPath = [sysName '/' workstationName num2str(ii) '/RandomNumbers_ProcessingTimes'];

    %Invert mean & variance to lognormal-specific parameters
    %(This is copied & pasted from function HELPER_DistribParamsFromMeanAndVar)
    m = ProcessingTime_logNormMeans(ii);
    v = ProcessingTime_logNormVars(ii);
    sigSq = log(v*exp(-2*log(m)) + 1);
    sig = sqrt(sigSq);
    mu = log(m) - sigSq/2;
    
    %Set the distribution type and parameters
    set_param(rngenPPath, 'Distribution', 'Lognormal');
    set_param(rngenPPath, 'thresholdLogn', num2str(0));
    set_param(rngenPPath, 'scaleLogn', num2str(mu)); 
    set_param(rngenPPath, 'shapeLogn', num2str(sig));
    
    %Also:  Turn off failures & repairs
    rngenTTFpath = [sysName '/' workstationName num2str(ii) '/RandomNumbers_TimeUntilFailure'];
    set_param(rngenTTFpath, 'Distribution', 'Gaussian (normal)');
    set_param(rngenTTFpath, 'meanNorm', num2str(2*simEndTime));
    set_param(rngenTTFpath, 'stdNorm', 'eps');
    rngenTTRpath = [sysName '/' workstationName num2str(ii) '/RandomNumbers_TimeToRepair'];
    set_param(rngenTTRpath, 'Distribution', 'Gaussian (normal)');
    set_param(rngenTTRpath, 'meanNorm', num2str(2*simEndTime));
    set_param(rngenTTRpath, 'stdNorm', 'eps');
end


%% Set Workstations' Queue Capacities and Number of Servers
for ii = 1 : nWks
    maskedSubsystemPath = [sysName '/' workstationName num2str(ii) '/GGkWorkstation_RandomCalendarTimeUntilPreempFailure'];
    set_param(maskedSubsystemPath, 'Capacity', num2str(AllWksQueueCapacities(ii)));
    set_param(maskedSubsystemPath, 'NumberOfServers', num2str(AllWksNumberServers(ii)));
end


%% Simulate
set_param(sysName, 'StartTime', num2str(0), 'StopTime', num2str(simEndTime));
se_randomizeseeds(sysName, 'Mode', 'All');
w1ID = 'Simulink:blocks:DivideByZero';
w1 = warning('off', w1ID);
w2ID = 'Simulink:Engine:OutputNotConnected';
w2 = warning('off', w2ID);
w3ID = 'Simulink:Engine:UnconnectedOutputLine';
w3 = warning('off', w3ID);
simout = sim(sysName, 'SaveOutput', 'on');
% warning(w1); %Reset state
% warning(w2); %Reset state
% warning(w3); %Reset state


%% Results
WIP_average = simout.get('WIP_average').signals.values(end);
CT_average = simout.get('CT_average').signals.values(end);
TH_average = simout.get('TH_average').signals.values(end);
