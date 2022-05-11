clear;
close all;

%% Read model from GUI
model = loadModel('battery_pack_17S6P_model.mat');

%% Set the number of max contact modes
for i = 1:614
    model.contacts_fem_fem(i).number_of_max_contact_modes = 1;
end

%% IC and add Air
model.addAir("air", 'data', 'data/air_linear_data.xlsx',...
    'dimensions', [242, 141, 158],...
    'starting_point', [-0.016, -0.126, -0.0075], ...
    'air_contact_bodies',...
    ["Component_CELL_CORE.*", "Component_CASING.*"], ...
    'air_contact_surf_ids',...
    [repmat({[1]}, 1, 102), {[2, 4, 5, 8, 10, 11, 13]}], ...
    'air_contact_alpha', 5, 'n_partitions', [10, 10, 10]);

model.setIC('.*', 'T', 30);

%% Model Preparation and run
model.saveModel("battery_pack_17S6P_before_prep");

tic;
model.flag_is_parallel = false;
model_struct = model.prepare();
prep_time = toc;

model.saveModel("battery_pack_17S6P_after_prep");

current = readtable("data/current.xlsx");
current.Properties.VariableNames = {'t','current'};
model_struct.ele_circ_electro = current;

tic;
model.run(10, 100, 'electroSubsteps',100, 'signals_data', model_struct,...
    'solver', 'Direct')
run_time = toc;

%% Post
% Elctro
model.plotCircuitVoltage("ele_circ")
model.plotSOCOverTime()
model.plotCurrentOverTime()

%% Thermal
model.plotMaxTempOverTime("Component_CELL_CORE.*")
model.plotMinTempOverTime("Component_CELL_CORE.*")
model.plotMeanTempOverTime("Component_CELL_CORE.*")

model.plotSolution("cells_terminals_holders_connectors", 3)
model.plotSolution("cells_terminals_holders_connectors", 50)
model.plotSolution("cells_terminals_holders_connectors", 100)
 
model.exportSolutionToCGNS("battery_pack_assembly", "battery_pack_17S6P_result.cgns");
model.saveModel("battery_pack_17S6P_results");
